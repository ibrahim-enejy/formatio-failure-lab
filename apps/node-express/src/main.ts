import express from 'express';
import cors from 'cors';
import * as bodyParser from 'body-parser';
import routes from './app/routes/routes';
import { getHealthz } from './app/routes/lab/lab.controller';
import HttpException from './app/models/http-exception.model';

const app = express();

/**
 * App Configuration
 */

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.get('/healthz', getHealthz);
app.use(routes);

// Serves images
app.use(express.static(__dirname + '/assets'));

app.get('/', (req: express.Request, res: express.Response) => {
  res.json({
    app: 'Formatio Open-Source Failure Lab',
    framework: 'Node.js 20+ (Express + Prisma)',
    documentation: 'https://github.com/ibrahim-enejy/formatio-failure-lab',
    healthz_endpoint: '/healthz',
    status_endpoint: '/api/lab/status',
    scenarios: {
      '01-heap-oom': 'POST /api/lab/scenarios/01-oom',
      '02-connection-hang': 'POST /api/lab/scenarios/02-hang',
      '03-unhandled-rejection': 'POST /api/lab/scenarios/03-unhandled-rejection',
      '04-event-loop-block': 'POST /api/lab/scenarios/04-event-loop-block?ms=5000',
      '09-persistent-storage': 'POST|GET /api/lab/storage',
      '12-regression': 'POST /api/lab/scenarios/12-regression',
      '14-secret-crash': 'POST /api/lab/scenarios/14-secret-crash',
    },
    message:
      'Deploy this repo on Formatio to test lightweight OpenTelemetry, built-in AI error advisory, autonomous fix PRs, and governed /mcp access.',
  });
});

/* eslint-disable */
app.use(
  (
    err: Error | HttpException,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction,
  ) => {
    // @ts-ignore
    if (err && err.name === 'UnauthorizedError') {
      return res.status(401).json({
        status: 'error',
        message: 'missing authorization credentials',
      });
      // @ts-ignore
    } else if (err && err.errorCode) {
      // @ts-ignore
      res.status(err.errorCode).json(err.message);
    } else if (err) {
      res.status(500).json(err.message);
    }
  },
);

/**
 * Server activation
 */

const HOST = process.env.HOST || '0.0.0.0';
const PORT = Number(process.env.PORT || 3000);

app.listen(PORT, HOST, () => {
  console.info(`server up on http://${HOST}:${PORT}`);
});
