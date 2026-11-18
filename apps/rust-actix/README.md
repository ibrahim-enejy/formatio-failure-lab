# Formatio Failure Lab: Rust / Actix-Web Microservice

> High-performance compiled async microservice designed for diagnosing Tokio runtime thread pool starvation, async mutex deadlocks, and connection queue overflows.

---

## Target Scenarios for Rust Rotation

1. **Async Mutex Contention & Tokio Worker Starvation:** Holding an async mutex across `.await` points under heavy concurrency.
2. **Channel Buffer Exhaustion:** Unbounded mpsc channel buffering causing out-of-memory under high ingestion pressure.
3. **Blocking System Calls in Tokio Context:** Calling blocking filesystem or CPU-intensive routines directly inside an async worker rather than `tokio::task::spawn_blocking`.

---

## Deployment to Formatio
- Formatio Railpack automatically builds Rust services via `cargo build --release`, producing a hyper-lean scratch container.
