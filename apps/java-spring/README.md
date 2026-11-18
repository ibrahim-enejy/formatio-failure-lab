# Formatio Failure Lab: Java / Spring Boot Microservice

> JVM-based enterprise service template configured for testing garbage collection pause stalls (Stop-the-World), HikariCP database pool exhaustion, and Metaspace memory leaks.

---

## Target Scenarios for Java Rotation

1. **HikariCP Connection Pool Exhaustion:** Leaking unclosed database transactions until all 10 worker threads are exhausted.
2. **JVM Metaspace OutOfMemoryError:** Dynamic class generation (e.g. CGLIB or bytecode proxy loops) exhausting non-heap Metaspace.
3. **Synchronous Thread Pool Deadlock:** Circular dependency between `@Async` tasks starving the Tomcat worker pool.

---

## Deployment to Formatio
- Formatio automatically detects Maven (`pom.xml`) or Gradle (`build.gradle`), provisions Eclipse Temurin JDK, and attaches the OpenTelemetry Java Auto-Instrumentation Agent.
