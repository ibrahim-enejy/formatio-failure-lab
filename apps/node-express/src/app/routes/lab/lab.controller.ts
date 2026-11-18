import { Request, Response, Router } from 'express';
import { triggerOOM, triggerHang } from '../article/article.controller';

const router = Router();

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

router.get('/lab/status', getLabStatus);
router.all('/lab/scenarios/01-oom', triggerOOM);
router.all('/lab/scenarios/02-hang', triggerHang);
router.all('/lab/scenarios/03-unhandled-rejection', triggerUnhandledRejection);
router.all('/lab/scenarios/04-event-loop-block', triggerEventLoopBlock);

export default router;
