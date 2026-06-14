# Changelog

All notable changes to this skill are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The version recorded here matches `metadata.version` in
[`SKILL.md`](dotnet-vertical-slice-best-practices/SKILL.md).

## [1.8.0] - 2026-06-14

### Added
- `dotnet-slice-example.md`: a complete, end-to-end golden-path slice on the skill's stack (domain
  entity, command, FluentValidation validator, handler, validation pipeline behavior, EF Core/Npgsql
  configuration with `xmin` concurrency, typed-union endpoint, registration, and migration command).
- `dotnet-security.md`: authentication, policy and resource-based authorization, ownership checks,
  the `ICurrentUser` pattern (handlers never touch `HttpContext`), secrets handling, and transport
  hardening (HTTPS/HSTS, CORS allow-list, rate limiting, security headers, over-posting protection).
- Handler rule in `dotnet-cqrs-slice.md` requiring caller identity via `ICurrentUser`, never
  `IHttpContextAccessor`, to keep the `Application` layer transport-free.

## [1.7.0] - 2026-06-14

### Changed
- Mediator default is now the free, source-generated **`Mediator` package (martinothamar/Mediator)**
  instead of a hand-rolled abstraction. It keeps a MediatR-compatible surface (`IRequest`,
  `IRequestHandler`, `ISender`, `IPipelineBehavior`) with compile-time dispatch and no licensing cost.
  A small first-party abstraction remains documented as the zero-dependency fallback.

### Added
- **Scalar** (`Scalar.AspNetCore`) as the interactive API reference UI layered over the official
  `Microsoft.AspNetCore.OpenApi` document, replacing Swagger UI (Swashbuckle stays out).
- **`Microsoft.Extensions.Http.Resilience`** (Polly v8 standard resilience handler) as the baseline
  for outbound HTTP calls.
- **Respawn** as the recommended way to reset database state between integration tests.
- An explicit **tests-are-opt-in** rule in `SKILL.md` and `dotnet-testing.md`: do not create or
  scaffold tests unless the user explicitly asks; the default behavior is no tests.

## [1.6.0] - 2026-06-13

### Changed
- The skill now targets **.NET 10 / C# 14 exclusively**. Removed all references to other .NET lines
  (.NET 8/9 support tables, "preserve the repo's current framework", LTS-vs-preview framing) across
  the platform-baseline, vertical-slice, validation, and migrations references.
- Dropped MediatR entirely as a recommendation. The skill now prescribes a **first-party mediator**
  (`ISender`/`IRequest`/`IRequestHandler`) owned by the `Application` layer, with a source-generated
  mediator named only as an optional license-free alternative.

### Added
- A **first-party pipeline-behavior scheme** (`IPipelineBehavior<,>` + `RequestHandlerDelegate`) that
  replaces MediatR pipeline behaviors for cross-cutting integrations (validation, logging,
  transactions, outbox/idempotency), with ordering and opt-in (marker interface) guidance.
- A **C# 14 coding-conventions** section in `dotnet-solution-topology.md`: file-scoped namespaces,
  primary constructors, no underscore-prefixed fields, current language features, and enforcement via
  `.editorconfig`/analyzers/`Directory.Build.props`.
- An "always use the current idioms" subsection in the platform baseline.

## [1.5.0] - 2026-06-13

### Fixed
- Corrected the .NET 9 support window in `dotnet-platform-baseline.md`: .NET 9 is
  Standard-Term Support (18 months) and reached end of life on 2026-05-12, not
  November 2026.
- Resolved the internal contradiction over where the `DbContext` lives. The skill now
  consistently places the `DbContext`, entity configurations, and provider setup in
  `Infrastructure`, with the migrations project owning only EF migrations and snapshots.
- Reworded the `SKILL.md` activation sentence that used "devops" and "databases" as verbs.

### Added
- `LICENSE` (MIT) so the skill can be legally consumed via `npx skills add`.
- Library-licensing guidance: MediatR, AutoMapper, and MassTransit moved to commercial
  licensing (2024–2025). References now stay library-neutral and document free
  alternatives (a minimal in-house `ISender` abstraction, or a source-generated mediator).
- Disclaimer clarifying that `AppHost` here is the backend composition root and is **not**
  the .NET Aspire orchestrator, plus a note on when Aspire is the better fit.
- 2026 .NET 10 vocabulary in the Minimal API and platform-baseline references:
  `TypedResults` with `Results<...>` union return types for automatic OpenAPI metadata,
  OpenTelemetry, built-in rate limiting, optimistic concurrency (`xmin` for Npgsql),
  and EF Core migration bundles as a deployment option alongside the dedicated migrator.
- A concrete `ErrorOr<T>` → `ProblemDetails` mapping example in the validation reference.

## [1.4.2] - 2026-05-13
- Enhanced `README.md` and `devops-github.md` with migration and validation guidance.

## [1.4.0] - 2026-05-12
- Added the `devops-github.md` reference for GitHub Actions build policy.

## [1.2.0]
- Added the solution-topology reference and expanded migration-project documentation.

## [1.1.1]
- Version maintenance.

## [1.1.0]
- Earlier published baseline of the skill.
