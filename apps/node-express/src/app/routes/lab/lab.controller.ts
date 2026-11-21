import * as fs from 'fs';
import * as path from 'path';
import { Request, Response, Router } from 'express';
import { triggerOOM, triggerHang } from '../article/article.controller';
import { calculateCheckoutTotal } from './discount.service';

const router = Router();
const EPHEMERAL_MARKER = '/tmp/formatio-ephemeral.json';

function persistentMarkerPath(): string {
  const dir = process.env.DATA_DIR || '/data';
  return path.join(dir, 'formatio-persistent.json');
}

function readJsonMarker(filePath: string): { exists: boolean; data: unknown } {
  try {
    if (!fs.existsSync(filePath)) {
      return { exists: false, data: null };
    }
    const raw = fs.readFileSync(filePath, 'utf8');
    return { exists: true, data: JSON.parse(raw) };
  } catch (err) {
    return { exists: false, data: { error: (err as Error).message } };
  }
}

/**
 * Readiness & Health Endpoint
 * GET /healthz
 */
export const getHealthz = async (req: Request, res: Response) => {
  if (process.env.SIMULATE_BAD_HEALTHCHECK === 'true') {
    return res.status(503).json({
      status: 'unhealthy',
      reason: 'SIMULATE_BAD_HEALTHCHECK=true',
      tip: 'Use Formatio Rollback to restore the previous successful deployment.',
    });
  }
  return res.status(200).json({
    status: 'ok',
    service: 'node-express',
    uptime_seconds: Math.floor(process.uptime()),
  });
};

/**
 * Health & Live System Telemetry Status
 * GET /api/lab/status
 */
export const getLabStatus = async (req: Request, res: Response) => {
  const mem = process.memoryUsage();
  return res.json({
    status: 'online',
    app: 'Formatio Failure Lab — Node/Express RealWorld API',
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
      '01-heap-oom': 'POST /api/lab/scenarios/01-oom or GET /api/articles/sabotage/oom',
      '02-connection-hang': 'POST /api/lab/scenarios/02-hang or GET /api/articles/sabotage/hang',
      '03-unhandled-rejection': 'POST /api/lab/scenarios/03-unhandled-rejection',
      '04-event-loop-block': 'POST /api/lab/scenarios/04-event-loop-block',
      '08-healthcheck': 'GET /healthz (503 when SIMULATE_BAD_HEALTHCHECK=true)',
      '09-persistent-storage': 'POST|GET /api/lab/storage',
      '12-regression': 'POST /api/lab/scenarios/12-regression',
      '14-secret-crash': 'POST /api/lab/scenarios/14-secret-crash',
    },
  });
};

/**
 * SABOTAGE 3: Unhandled Async Rejection (Silent Event Loop Crash)
 * POST /api/lab/scenarios/03-unhandled-rejection
 */
export const triggerUnhandledRejection = async (req: Request, res: Response) => {
  console.log('[Sabotage] Triggering unhandled async promise rejection in detached worker...');
  res.status(202).json({
    status: 'triggered',
    scenario: '03-unhandled-rejection',
    message: 'Unhandled promise rejection scheduled in 250ms.',
  });

  setTimeout(() => {
    Promise.reject(
      new Error(
        'Formatio Lab Injected Error: Unhandled async database transaction timeout inside order reconciliation worker.'
      )
    );
  }, 250);
};

/**
 * SABOTAGE 4: Synchronous CPU Lockup / Event Loop Starvation
 * POST /api/lab/scenarios/04-event-loop-block
 */
export const triggerEventLoopBlock = async (req: Request, res: Response) => {
  const durationMs = parseInt((req.query.ms as string) || '5000', 10);
  console.log(`[Sabotage] Blocking Node.js event loop synchronously for ${durationMs}ms...`);
  const start = Date.now();
  while (Date.now() - start < durationMs) {
    // Busy loop starving all other incoming HTTP requests
    Math.random() * Math.random();
  }
  return res.json({
    status: 'resolved',
    scenario: '04-event-loop-block',
    blocked_ms: durationMs,
    message: `Event loop was completely starved for ${durationMs}ms. All concurrent requests queued or timed out.`,
  });
};

/**
 * SCENARIO 09: Ephemeral /tmp vs. Persistent Volume Marker
 * POST /api/lab/storage | GET /api/lab/storage
 */
export const writeStorageMarker = async (req: Request, res: Response) => {
  const marker = {
    written_at: new Date().toISOString(),
    marker_id: (req.body && req.body.marker_id) || `marker-${Date.now()}`,
  };

  fs.writeFileSync(EPHEMERAL_MARKER, JSON.stringify(marker, null, 2), 'utf8');

  const pPath = persistentMarkerPath();
  let persistentWritten = false;
  let persistentError: string | null = null;
  try {
    fs.mkdirSync(path.dirname(pPath), { recursive: true });
    fs.writeFileSync(pPath, JSON.stringify(marker, null, 2), 'utf8');
    persistentWritten = true;
  } catch (err) {
    persistentError = (err as Error).message;
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
};

export const readStorageMarker = async (_req: Request, res: Response) => {
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
};

/**
 * SCENARIO 12: Deterministic 1-Line Checkout Regression
 * POST /api/lab/scenarios/12-regression
 */
export const triggerRegression = async (req: Request, res: Response) => {
  const result = calculateCheckoutTotal(req.body || {});
  return res.json({ status: 'ok', result });
};

/**
 * SCENARIO 14: Govern /mcp Secret Redaction Crash Test
 * Checks secret presence by key name only; never logs or returns raw values.
 * POST /api/lab/scenarios/14-secret-crash
 */
export const triggerSecretCrash = async (_req: Request, _res: Response) => {
  const hasStripeKey = Boolean(process.env.STRIPE_SECRET_KEY);
  const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
  const err = new Error(
    `PaymentGatewayConfigError: missing or invalid checkout signing webhook secret (STRIPE_SECRET_KEY present=${hasStripeKey}, DATABASE_URL present=${hasDatabaseUrl})`
  );
  err.name = 'PaymentGatewayConfigError';
  throw err;
};

router.get('/lab/status', getLabStatus);
router.post('/lab/storage', writeStorageMarker);
router.get('/lab/storage', readStorageMarker);
router.all('/lab/scenarios/01-oom', triggerOOM);
router.all('/lab/scenarios/02-hang', triggerHang);
router.all('/lab/scenarios/03-unhandled-rejection', triggerUnhandledRejection);
router.all('/lab/scenarios/04-event-loop-block', triggerEventLoopBlock);
router.post('/lab/scenarios/12-regression', triggerRegression);
router.post('/lab/scenarios/14-secret-crash', triggerSecretCrash);

export default router;
