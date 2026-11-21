# Formatio Failure Lab: Java and Spring Boot template

> **Status:** Template stub (application source code planned — deploy `apps/node-express`, `apps/nextjs-15`, `apps/python-fastapi`, or `apps/go-gin` for live runnable tests today).

JVM enterprise service template planned for testing garbage collection pause stalls (Stop-the-World), HikariCP database pool exhaustion, and Metaspace memory leaks.

## Planned scenarios for Java

1. **HikariCP connection pool exhaustion:** Leaking unclosed database transactions until all worker threads are exhausted.
2. **JVM Metaspace `OutOfMemoryError`:** Dynamic class generation exhausting non-heap Metaspace.
3. **Synchronous thread pool deadlock:** Circular dependency between `@Async` tasks starving the Tomcat worker pool.

## Deployment to Formatio

When runnable Java source is added here, Formatio Railpack detects Maven (`pom.xml`) or Gradle (`build.gradle`), provisions Eclipse Temurin JDK, and attaches the OpenTelemetry Java agent (`v2.32.0`) plus `formatio-otel-javaagent-extension` via `JAVA_TOOL_OPTIONS`.
