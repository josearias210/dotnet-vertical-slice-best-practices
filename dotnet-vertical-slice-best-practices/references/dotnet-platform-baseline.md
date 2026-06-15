# .NET Platform Baseline

This skill targets **.NET 10 / C# 14 exclusively**. Treat that as a fixed assumption, not a choice to
re-evaluate per repo. Do not introduce, recommend, or fall back to any other .NET line. If a repo is
not yet on .NET 10, modernizing it to .NET 10 is the path; do not author slices against an older
runtime.

## Review date

Last reviewed: 2026-06-13. Re-verify the official .NET 10 support window if this baseline is reused
long after this date.

## Fixed baseline

- Runtime: `.NET 10` (LTS, supported through November 2028).
- Web stack: `ASP.NET Core 10`.
- ORM: `EF Core 10` (LTS, aligned to `.NET 10`).
- Language: `C# 14`.

These move together as one coordinated baseline. SDK, ASP.NET Core, EF Core, the database provider,
and the language version are upgraded as a set, never as isolated package bumps.

## Always use the current idioms

Default to the latest .NET 10 / C# 14 idioms; do not write code in an older style "to be safe":

- file-scoped namespaces (single-line `namespace App.Feature;`), never block-scoped namespaces;
- primary constructors for handlers, services, and DI-injected types instead of a hand-written
  constructor plus backing fields;
- no underscore-prefixed field names (`_repository`); reference the primary-constructor parameter
  directly, which removes most private backing fields entirely;
- collection expressions (`[]`), target-typed `new`, pattern matching, and `required` members where
  they make intent clearer;
- centralized global usings and `ImplicitUsings`.

See `dotnet-solution-topology.md` for how these are enforced via `.editorconfig`, analyzers, and
`Directory.Build.props`.

## .NET 10 baseline checks

When building or reviewing a .NET 10 backend, confirm these baseline practices:

- pin the SDK with `global.json`;
- expose liveness/readiness using ASP.NET Core health checks rather than only a hand-written endpoint;
- generate OpenAPI during build when CI or contract review needs an artifact;
- return Minimal API results as `TypedResults` with `Results<...>` union types so the generated
  OpenAPI document carries accurate status codes without manual `Produces<>()` calls;
- centralize `ProblemDetails` metadata such as trace and correlation identifiers;
- use fluent request validators instead of `DataAnnotations`;
- verify Minimal API request validation behavior with an invalid HTTP request;
- use **Serilog as the mandatory logging provider** — console by default, and logs exported to the
  OpenTelemetry collector *through Serilog's OTLP sink* when OpenTelemetry is enabled; wire tracing and
  metrics via the OpenTelemetry SDK. Prefer `[LoggerMessage]` source-generated logging on hot paths
  (it still flows through Serilog). See `dotnet-observability.md`;
- enable built-in rate limiting (`AddRateLimiter`) on public endpoints when load shaping matters;
- model optimistic concurrency for mutating commands (with Npgsql, the `xmin` system column maps
  cleanly to an EF Core concurrency token);
- enable connection resiliency for PostgreSQL (`EnableRetryOnFailure`) and consider
  `AddDbContextPool` for high-throughput services;
- for outbound HTTP calls, use `IHttpClientFactory` with `Microsoft.Extensions.Http.Resilience`
  (the Polly v8-based standard resilience handler) rather than hand-rolled retry/timeout code;
- decide deliberately how migrations reach each environment: a dedicated migrator service, an EF
  Core migration bundle (`dotnet ef migrations bundle`), or both. Do not let API startup silently
  become the production schema-mutation path.

## Dependency licensing

Keep the dependency set healthy and license-clean:

- Do not depend on `MediatR`, `AutoMapper`, or `MassTransit`. They moved to commercial licensing
  (2024–2025) and require a paid license above a revenue threshold. This skill deliberately avoids
  them; see `dotnet-cqrs-slice.md` for the free source-generated `Mediator` package (with a
  first-party fallback) used instead.
- Keep request validation library-neutral ("fluent request validators") so the pattern does not bind
  the project to a single package's licensing or support trajectory.
- Before adding any cross-cutting infrastructure library, confirm its license is free for the
  project's use and prefer a small first-party abstraction when the need is narrow.

## Sources (re-verify against these)

The perishable facts in this skill — support windows, language/runtime versions, and dependency
licensing — must be re-verified against their authoritative sources, not memory, when the review date
above goes stale. Update this file (and the `Last reviewed` date) when any of these change.

- .NET support policy and lifecycle: <https://dotnet.microsoft.com/platform/support/policy/dotnet-core>
- .NET release notes and dates: <https://github.com/dotnet/core/blob/main/releases.md>
- EF Core releases and lifecycle: <https://learn.microsoft.com/ef/core/what-is-new/>
- ASP.NET Core OpenAPI: <https://learn.microsoft.com/aspnet/core/fundamentals/openapi/>
- HTTP resilience (`Microsoft.Extensions.Http.Resilience`): <https://learn.microsoft.com/dotnet/core/resilience/http-resilience>
- Serilog: <https://serilog.net/>
- Serilog OpenTelemetry sink: <https://github.com/serilog/serilog-sinks-opentelemetry>
- OpenTelemetry for .NET: <https://opentelemetry.io/docs/languages/dotnet/>
- Npgsql EF Core provider: <https://www.npgsql.org/efcore/>
- Source-generated mediator (`Mediator`): <https://github.com/martinothamar/Mediator>
- `ErrorOr`: <https://github.com/amantinband/error-or>
- FluentValidation: <https://docs.fluentvalidation.net/>
- Scalar API reference UI: <https://github.com/scalar/scalar>
- Testcontainers for .NET: <https://dotnet.testcontainers.org/>
- Respawn: <https://github.com/jbogard/Respawn>
- Agent Skills standard: <https://agentskills.io/>

Treat these as the verification trail behind the skill's opinions; they are not bundled or scraped,
only consulted when the version-sensitive guidance is reviewed.
