---
name: dotnet-vertical-slice-best-practices
description: Guide for implementing and evolving .NET 10 / C# 14 backends using vertical slices, a source-generated mediator and pipeline, fluent validation, PostgreSQL persistence, EF Core 10 migrations, host/API composition, and GitHub Actions CI. Use when creating or changing backend features, endpoints, handlers, contracts, persistence, migrations, startup composition, or .NET 10 backend behavior. Follow only the steps relevant to the current change.
compatibility: Designed for Agent Skills-compatible coding assistants, including OpenAI Codex, GitHub Copilot-compatible environments, and Claude Code-style clients.
metadata:
  version: "2.0.0"
---

# .NET 10 Backend Vertical Slice

Use this skill when backend code needs to be planned, implemented, deployed, persisted, or refined in a .NET 10 / C# 14 application that follows a vertical-slice style.

## Core rule

Keep behavior local to the use case, preserve stable API contracts, and treat persistence, validation,
error handling, and migrations as part of the same backend change.

This skill targets **.NET 10 / C# 14 exclusively** and dispatches use cases through the free
**source-generated `Mediator` package** (never MediatR; a first-party abstraction is the
zero-dependency fallback). Use current language idioms — file-scoped namespaces, primary
constructors, no underscore-prefixed fields — and do not reference or target other .NET versions.
See `dotnet-platform-baseline.md`.

**Tests are opt-in.** Do not create or scaffold tests unless the user explicitly asks for them. The
default is to implement the change without tests; only load `dotnet-testing.md` and write tests when
testing is requested.

## Working flow

1. Inspect the repository structure and preserve valid local conventions (naming patterns, folder structures, and coding standards).
2. Identify the affected use case, route, request, response, and persistence impact. If multiple slices are affected, ensure consistency across all impacted slices.
3. Minimize logic in the transport layer (endpoint registration, HTTP result mapping, and request deserialization); keep all business logic and validation within the same handler or module associated with the slice.
4. Address concerns in this priority order (adjust if a migration or persistence change is a prerequisite for the change):
   - First: validation rules and expected failure paths.
   - Second: authorization and ownership checks.
   - Third: migrations and persistence changes.
5. Load the references that apply using the decision table below:

   | Task involves…                                                                 | Load this reference              |
   |--------------------------------------------------------------------------------|----------------------------------|
   | Minimal APIs, route groups, HTTP result mapping, or OpenAPI                    | dotnet-minimal-api.md            |
   | Commands, queries, handlers, or mediator-dispatched slices                      | dotnet-cqrs-slice.md             |
   | Slice structure, file responsibilities, or deciding when to split a slice        | dotnet-vertical-slice.md         |
   | Request/business validation, error modeling, or HTTP failure mapping             | dotnet-validation-and-errors.md  |
   | A complete worked slice / end-to-end example on this stack                       | dotnet-slice-example.md          |
   | Authentication, authorization, ownership, current-user identity, or secrets      | dotnet-security.md               |
   | Startup composition, project boundaries, or solution-wide build/package defaults | dotnet-solution-topology.md      |
   | Dedicated migrator or containerized local backend startup                        | dotnet-migrations-project.md; create or update `compose.yml` so `docker compose up` runs dependencies and migrations in order |
   | GitHub Actions build workflows, release images, or backend/migrator artifact versioning | devops-github.md |
   | .NET 10 baseline, current C# 14 idioms, or dependency licensing                 | dotnet-platform-baseline.md |
   | Unit or integration tests for a slice, `WebApplicationFactory`, or Testcontainers | dotnet-testing.md |

6. For .NET 10 host-composition work, check whether the change should include SDK pinning, real
   health checks, OpenAPI build artifacts, fluent request validation, or centralized `ProblemDetails`
   metadata.
7. Run the most relevant verification for the touched backend surface.

## Required checklist

For every meaningful backend change, reason through the following categories in order:

**1. Use Case and Contracts** (start here)
- slice or feature affected;
- command or query semantics;
- endpoint and route behavior;
- request and response contracts;

**2. Validation and Authorization**
- validation rules;
- expected business errors;
- authorization and ownership checks;

**3. Persistence and Migrations**
- persistence impact;
- migration impact;

**4. Composition and Caller Impact**
- host/composition or solution-boundary impact when relevant;
- caller impact.

## Reference files

Load only the references that apply:

- [dotnet-minimal-api.md](references/dotnet-minimal-api.md)
  Covers Minimal API endpoint structure, route groups, `IEndpoint` registration, result mapping, `ProblemDetails`, and OpenAPI expectations.
- [dotnet-cqrs-slice.md](references/dotnet-cqrs-slice.md)
  Covers CQRS slice structure, the source-generated `Mediator` (`ISender`) and pipeline-behavior scheme, request shapes, handler rules, and query/command boundaries.
- [dotnet-slice-example.md](references/dotnet-slice-example.md)
  A complete end-to-end worked slice (entity, command, validator, handler, behavior, EF config, endpoint, migration) on this skill's stack.
- [dotnet-security.md](references/dotnet-security.md)
  Covers authentication, authorization, ownership checks, the `ICurrentUser` pattern, secrets, and transport hardening.
- [dotnet-vertical-slice.md](references/dotnet-vertical-slice.md)
  Explains slice structure, file responsibilities, contract boundaries, and version-discipline expectations.
- [dotnet-validation-and-errors.md](references/dotnet-validation-and-errors.md)
  Covers request validation, business validation, expected failure modeling, and HTTP response consistency.
- [dotnet-migrations-project.md](references/dotnet-migrations-project.md)
  Covers dedicated EF Core migrations projects, executable migration runners, Compose orchestration, migration quality, and persistence-change checks.
- [dotnet-solution-topology.md](references/dotnet-solution-topology.md)
  Covers `AppHost` versus `Api` responsibilities, `Directory.Build.props`, `Directory.Packages.props`, and container-build expectations.
- [dotnet-platform-baseline.md](references/dotnet-platform-baseline.md)
  Fixes the .NET 10 / C# 14 baseline, the current-idiom rules, the .NET 10 baseline checks, and dependency-licensing constraints.
- [devops-github.md](references/devops-github.md)
  Covers GitHub Actions build triggers on `main`, backend and migrator image artifacts, and shared image-tag versioning.
- [dotnet-testing.md](references/dotnet-testing.md)
  Covers unit versus integration test layering, `WebApplicationFactory`, Testcontainers for PostgreSQL, and the slice test checklist.

## Output shape

When reporting implementation work, prefer this structure:

```markdown
## Scope

## Skills Used

## Files Changed

## Impacted Contracts

## Persistence And Migrations

## Verification Run

## Frontend Impact

## Open Risks
```
