FROM python:3.13-slim

WORKDIR /app

# Formatio's intake speaks OTLP/HTTP for traces only; disabling metrics/logs exporters prevents 404 noise.
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    OTEL_TRACES_EXPORTER=otlp_proto_http \
    OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD python3 -c "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\", \"8000\")}/healthz')" || exit 1

CMD ["sh", "-c", "exec opentelemetry-instrument uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
