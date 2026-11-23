'use strict';

// Stock OpenTelemetry auto-instrumentation is started via `--require @opentelemetry/auto-instrumentations-node/register`.
const fs = require('fs');
const path = require('path');
const express = require('express');
const { SpanStatusCode, trace } = require('@opentelemetry/api');
const { cartTotal, calculateCheckoutTotal } = require('./discount');

const tracer = trace.getTracer('failure-lab-node-express');
const app = express();
app.use(express.json());

const EPHEMERAL_MARKER = '/tmp/formatio-ephemeral.json';

function persistentMarkerPath() {
  const dir = process.env.DATA_DIR || '/data';
  return path.join(dir, 'formatio-persistent.json');
}

function readJsonMarker(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return { exists: false, data: null };
    }
    return { exists: true, data: JSON.parse(fs.readFileSync(filePath, 'utf8')) };
  } catch (err) {
    return { exists: false, data: { error: err.message } };
  }
}

class PriceFormatError extends Error {
  name = 'PriceFormatError';
}

class NotFoundError extends Error {
  name = 'NotFoundError';
  status = 404;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function priceCart(cart) {
  return cart.reduce((sum, item) => {
    const price = Number(item.price);
    if (Number.isNaN(price)) {
      throw new PriceFormatError(`cannot price ${item.sku}: "${item.price}"`);
    }
    return sum + price * item.qty;
  }, 0);
}

function renderDashboard(data) {
  return [
    `Welcome back, ${data.profile.name}`,
    `Recommended: ${data.recommendations.map((r) => r.title).join(', ')}`,
    `Loyalty: ${data.loyalty.points.toLocaleString()} points (${data.loyalty.value} ${data.loyalty.currency})`,
    '',
  ].join('\n');
}

app.get('/', (_req, res) => {
  res.json({
    lab: 'Formatio Open-Source Failure Lab',
    framework: 'Node.js / Express 5 (OTel auto-instrumented)',
    status_url: '/api/lab/status',
    routes: [
      '/healthz',
      '/ok',
      '/slow?ms=1500',
      '/exception',
      '/not-found/:id',
      '/status-500',
      '/crash',
      '/downstream?path=/exception',
      '/checkout[?healthy=1]',
      '/dashboard[?healthy=1]',
      '/ai-sre/cart-total[?empty=1]',
      '/api/lab/storage',
      '/api/lab/scenarios/01-oom',
      '/api/lab/scenarios/02-hang',
      '/api/lab/scenarios/03-unhandled-rejection',
      '/api/lab/scenarios/04-event-loop-block',
      '/api/lab/scenarios/05-pool-lockup',
      '/api/lab/scenarios/12-regression',
      '/api/lab/scenarios/14-secret-crash',
    ],
  });
});

// Scenario 08: returns 503 when SIMULATE_BAD_HEALTHCHECK=true
app.get('/healthz', (_req, res) => {
  if (process.env.SIMULATE_BAD_HEALTHCHECK === 'true') {
    return res.status(503).json({
      status: 'unhealthy',
      reason: 'SIMULATE_BAD_HEALTHCHECK=true',
      tip: 'Use Formatio Roll back to restore the previous successful deployment.',
    });
  }
  return res.status(200).json({
    status: 'ok',
    service: 'node-express',
    uptime_seconds: Math.floor(process.uptime()),
  });
});

app.get('/api/lab/status', (_req, res) => {
  const mem = process.memoryUsage();
  res.json({
    status: 'online',
    app: 'Formatio Failure Lab — Node.js/Express 5 (OTel)',
    runtime: {
      node: process.version,
      platform: process.platform,
      arch: process.arch,
      pid: process.pid,
      uptime_seconds: Math.floor(process.uptime()),
    },
    memory: {
      rss_mb: Math.round((mem.rss / 1024 / 1024) * 100) / 100,
      heap_total_mb: Math.round((mem.heapTotal / 1024 / 1024) * 100) / 100,
      heap_used_mb: Math.round((mem.heapUsed / 1024 / 1024) * 100) / 100,
      external_mb: Math.round((mem.external / 1024 / 1024) * 100) / 100,
    },
    scenarios: {
      '01-heap-oom': 'POST /api/lab/scenarios/01-oom',
      '02-connection-hang': 'POST /api/lab/scenarios/02-hang',
      '03-unhandled-rejection': 'POST /api/lab/scenarios/03-unhandled-rejection',
      '04-event-loop-block': 'POST /api/lab/scenarios/04-event-loop-block',
      '05-pool-lockup': 'POST /api/lab/scenarios/05-pool-lockup',
      '08-healthcheck': 'GET /healthz',
      '09-persistent-storage': 'POST|GET /api/lab/storage',
      '12-regression': 'POST /api/lab/scenarios/12-regression | GET /ai-sre/cart-total?empty=1',
      '14-secret-crash': 'POST /api/lab/scenarios/14-secret-crash',
      '17-distributed-checkout': 'GET /checkout',
      '18-distributed-dashboard': 'GET /dashboard',
    },
  });
});

// Scenario 09: Ephemeral /tmp vs. persistent DATA_DIR (/data) volume verification
app.post('/api/lab/storage', (req, res) => {
  const marker = {
    written_at: new Date().toISOString(),
    marker_id: (req.body && req.body.marker_id) || `marker-${Date.now()}`,
  };
  fs.writeFileSync(EPHEMERAL_MARKER, JSON.stringify(marker, null, 2), 'utf8');

  const pPath = persistentMarkerPath();
  let persistentWritten = false;
  let persistentError = null;
  try {
    fs.mkdirSync(path.dirname(pPath), { recursive: true });
    fs.writeFileSync(pPath, JSON.stringify(marker, null, 2), 'utf8');
    persistentWritten = true;
  } catch (err) {
    persistentError = err.message;
  }

  return res.status(persistentWritten ? 201 : 207).json({
    scenario: '09-persistent-volume-and-terminal',
    ephemeral_path: EPHEMERAL_MARKER,
    ephemeral_written: true,
    persistent_path: pPath,
    persistent_written: persistentWritten,
    persistent_error: persistentError,
    marker,
  });
});

app.get('/api/lab/storage', (_req, res) => {
  const ephemeral = readJsonMarker(EPHEMERAL_MARKER);
  const pPath = persistentMarkerPath();
  const persistent = readJsonMarker(pPath);
  return res.json({
    scenario: '09-persistent-volume-and-terminal',
    ephemeral_path: EPHEMERAL_MARKER,
    ephemeral_present: ephemeral.exists,
    ephemeral_data: ephemeral.data,
    persistent_path: pPath,
    persistent_present: persistent.exists,
    persistent_data: persistent.data,
  });
});

// Stock OTel grouping & latency routes
app.get('/ok', async (_req, res) => {
  await tracer.startActiveSpan('load dashboard', async (span) => {
    for (const step of ['query users', 'query orders', 'render']) {
      await tracer.startActiveSpan(step, async (child) => {
        await sleep(5 + Math.random() * 20);
        child.end();
      });
    }
    span.end();
  });
  res.send('ok\n');
});

app.get('/slow', async (req, res) => {
  const ms = Number(req.query.ms) > 0 ? Number(req.query.ms) : 1500;
  await tracer.startActiveSpan('slow work', async (span) => {
    span.setAttribute('sleep.ms', ms);
    await sleep(ms);
    span.end();
  });
  res.send(`slept ${ms}ms\n`);
});

app.get('/exception', () => {
  const invoice = { lines: undefined };
  return invoice.lines.reduce((sum, line) => sum + line.total, 0);
});

app.get('/not-found/:id', (req) => {
  throw new NotFoundError(`user ${req.params.id} not found`);
});

app.get('/status-500', (_req, res) => {
  trace.getActiveSpan()?.setStatus({
    code: SpanStatusCode.ERROR,
    message: 'upstream quota exhausted',
  });
  res.status(500).send('upstream quota exhausted\n');
});

app.get('/crash', async () => {
  await sleep(5);
  JSON.parse('{"broken": ');
});

app.get('/downstream', async (req, res) => {
  const base = process.env.DOWNSTREAM_URL || 'http://python-fastapi:8000';
  const targetPath = req.query.path || '/exception';
  const response = await fetch(base + targetPath);
  const body = await response.text();
  if (response.status >= 500) {
    trace.getActiveSpan()?.setStatus({
      code: SpanStatusCode.ERROR,
      message: `downstream answered ${response.status}`,
    });
    res.status(502);
  }
  res.send(`downstream ${base}${targetPath} → ${response.status}: ${body}`);
});

// Scenario 17: Frontend swallows PriceFormatError; Python crashes two hops away
app.get('/checkout', async (req, res) => {
  const ordersUrl = process.env.ORDERS_URL || process.env.GO_URL || 'http://go-gin:8080';
  const cart = req.query.healthy
    ? [
        { sku: 'kb-01', price: '1299.00', qty: 1 },
        { sku: 'mouse-02', price: '49.90', qty: 2 },
      ]
    : [
        { sku: 'kb-01', price: '1,299.00', qty: 1 },
        { sku: 'mouse-02', price: '49.90', qty: 2 },
      ];

  const total = tracer.startActiveSpan('price cart', (span) => {
    try {
      return priceCart(cart);
    } catch (err) {
      // Intentional bug: records exception on span and passes total: null downstream.
      span.recordException(err);
      span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
      return null;
    } finally {
      span.end();
    }
  });

  const response = await fetch(`${ordersUrl}/orders`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      items: cart.map(({ sku, qty }) => ({ sku, qty })),
      total,
    }),
  });
  const body = await response.text();
  if (!response.ok) {
    trace.getActiveSpan()?.setStatus({
      code: SpanStatusCode.ERROR,
      message: `checkout failed: orders answered ${response.status}`,
    });
    return res.status(502).send(`checkout failed: ${body}\n`);
  }
  return res.send(`order placed: ${body}\n`);
});

// Scenario 18: Deep rates-db outage cascades across Go + Python into frontend TypeError
app.get('/dashboard', async (req, res) => {
  const apiUrl = process.env.GO_URL || process.env.ORDERS_URL || 'http://go-gin:8080';
  const suffix = req.query.healthy ? '?healthy=1' : '';
  const response = await fetch(`${apiUrl}/api/dashboard${suffix}`);
  const data = await response.json();
  res.send(renderDashboard(data));
});

// Scenario 12 + Direct AI SRE Automatic Fix PR fixtures
app.get('/ai-sre/cart-total', (req, res) => {
  const cart = req.query.empty === '1' ? {} : { items: [{ cents: 250 }] };
  res.json({ totalCents: cartTotal(cart) });
});

app.post('/api/lab/scenarios/12-regression', (req, res) => {
  const result = calculateCheckoutTotal(req.body || {});
  res.json({ status: 'ok', result });
});

// Scenarios 01–05 & 14: Runtime stress + Govern /mcp redaction crash
app.all('/api/lab/scenarios/01-oom', (_req, res) => {
  console.log('[Sabotage] Allocating unbounded Buffer blocks to induce container OOM...');
  global.__formatioOomLeak = global.__formatioOomLeak || [];
  setInterval(() => {
    const block = Buffer.alloc(10 * 1024 * 1024, 1);
    global.__formatioOomLeak.push(block);
  }, 15);
  res.status(202).json({
    status: 'triggered',
    scenario: '01-heap-oom-crash',
    message: 'Unbounded 10MB Buffer allocation started.',
  });
});

app.all('/api/lab/scenarios/02-hang', async (_req, res) => {
  console.log('[Sabotage] Simulating 15-second upstream webhook stall...');
  await sleep(15000);
  res.json({
    status: 'resolved',
    scenario: '02-connection-starvation-hang',
    message: 'Simulated 15-second upstream wait completed.',
  });
});

app.all('/api/lab/scenarios/05-pool-lockup', async (_req, res) => {
  console.log('[Sabotage] Simulating 15-second database pool starvation...');
  await sleep(15000);
  res.json({
    status: 'resolved',
    scenario: '05-postgres-pool-lockup',
    message: 'Simulated 15-second connection pool wait completed.',
  });
});

app.all('/api/lab/scenarios/03-unhandled-rejection', (_req, res) => {
  console.log('[Sabotage] Scheduling detached unhandled Promise rejection in 250ms...');
  res.status(202).json({
    status: 'triggered',
    scenario: '03-unhandled-promise-rejection',
    message: 'Unhandled promise rejection scheduled in 250ms.',
  });
  setTimeout(() => {
    Promise.reject(
      new Error('Formatio Lab Injected Error: Unhandled async database transaction timeout inside order reconciliation worker.')
    );
  }, 250);
});

app.all('/api/lab/scenarios/04-event-loop-block', (req, res) => {
  const durationMs = parseInt(String(req.query.ms || '5000'), 10);
  console.log(`[Sabotage] Blocking Node.js event loop synchronously for ${durationMs}ms...`);
  const start = Date.now();
  while (Date.now() - start < durationMs) {
    Math.random() * Math.random();
  }
  res.json({
    status: 'resolved',
    scenario: '04-event-loop-block',
    blocked_ms: durationMs,
    message: `Event loop was blocked synchronously for ${durationMs}ms.`,
  });
});

app.post('/api/lab/scenarios/14-secret-crash', (_req, _res, next) => {
  const hasStripeKey = Boolean(process.env.STRIPE_SECRET_KEY);
  const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
  const err = new Error(
    `PaymentGatewayConfigError: missing or invalid checkout signing webhook secret (STRIPE_SECRET_KEY present=${hasStripeKey}, DATABASE_URL present=${hasDatabaseUrl})`
  );
  err.name = 'PaymentGatewayConfigError';
  return next(err);
});

app.use((err, _req, res, _next) => {
  const span = trace.getActiveSpan();
  span?.recordException(err);
  span?.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
  res.status(err.status ?? 500).json({
    error: err.name || 'Error',
    message: err.message,
  });
});

const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
  console.log(
    `failure-lab-node-express listening on :${port}, exporting OTLP to ${process.env.OTEL_EXPORTER_OTLP_ENDPOINT || '(unset)'}`
  );
});

process.on('SIGTERM', () => {
  server.close();
  setTimeout(() => process.exit(0), 5000).unref();
});
