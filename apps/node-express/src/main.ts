import express from 'express';
import cors from 'cors';
import * as bodyParser from 'body-parser';
import routes from './app/routes/routes';
import HttpException from './app/models/http-exception.model';

const app = express();

/**
 * App Configuration
 */

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(routes);

// Serves images
app.use(express.static(__dirname + '/assets'));

app.get('/', (req: express.Request, res: express.Response) => {
  res.json({
    app: 'Formatio Open-Source Failure Lab',
    framework: 'Node.js 20+ (Express + Prisma)',
    documentation: 'https://github.com/ibrahim-enejy/formatio-failure-lab',
    status_endpoint: '/api/lab/status',
    scenarios: {
      '01-heap-oom': 'POST /api/lab/scenarios/01-oom',
      '02-connection-hang': 'POST /api/lab/scenarios/02-hang',
      '03-unhandled-rejection': 'POST /api/lab/scenarios/03-unhandled-rejection',
      '04-event-loop-block': 'POST /api/lab/scenarios/04-event-loop-block?ms=5000',
    },
    message: 'Deploy this repo on Formatio to test zero-code OpenTelemetry and AI SRE incident recovery.',
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

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.info(`server up on port ${PORT}`);
});
