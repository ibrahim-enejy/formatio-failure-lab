FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

# Formatio's intake serves OTLP/HTTP traces only; disabling metrics/logs exporters prevents 404 log noise.
ENV PORT=3000 \
    DATA_DIR=/data \
    NODE_ENV=production \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none \
    OTEL_NODE_RESOURCE_DETECTORS=env,host,os,process,serviceinstance,container

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/healthz').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

# Exec node directly (not npm start) so SIGTERM flushes final OTLP spans cleanly.
CMD ["node", "--require", "@opentelemetry/auto-instrumentations-node/register", "app.js"]
