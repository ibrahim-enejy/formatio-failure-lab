# Formatio Failure Lab: Rust and Actix-Web template

> **Status:** Template stub (application source code planned — deploy `apps/node-express`, `apps/nextjs-15`, `apps/python-fastapi`, or `apps/go-gin` for live runnable tests today).

Compiled async microservice template planned for diagnosing Tokio runtime thread pool starvation, async mutex deadlocks, and channel queue overflows.

## Planned scenarios for Rust

1. **Async mutex contention and Tokio worker starvation:** Holding an async mutex across `.await` points under heavy concurrency.
2. **Channel buffer exhaustion:** Unbounded mpsc channel buffering causing out-of-memory under heavy ingestion.
3. **Blocking system calls inside Tokio:** Calling blocking filesystem or CPU routines on an async worker rather than `tokio::task::spawn_blocking`.

## Deployment to Formatio

Formatio builds Rust services from `Cargo.toml` or a multi-stage `Dockerfile` and exports standard OTLP traces to `/otlp/v1/traces`.
