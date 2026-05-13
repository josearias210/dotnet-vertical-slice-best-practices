---
name: dotnet-vertical-slice-best-practices
description: Implement and evolve .NET backends using vertical slices, explicit validation and error handling, PostgreSQL persistence, and dedicated EF Core migrations. Use when a coding assistant needs to create or change backend features, endpoints, commands, queries, handlers, contracts, persistence, or modernization-sensitive .NET backend behavior.
compatibility: Designed for Agent Skills-compatible coding assistants, including OpenAI Codex, GitHub Copilot-compatible environments, and Claude Code-style clients.
metadata:
  version: "1.1.1"
---

# .NET Backend Vertical Slice

Use this skill when backend code needs to be planned, implemented, or refined in a .NET application that follows a vertical-slice style.

## Core rule

Keep behavior local to the use case, preserve stable API contracts, and treat persistence, validation,
error handling, and migrations as part of the same backend change.

## Working flow

1. Inspect the repository structure and preserve valid local conventions.
2. Identify the affected use case, route, request, response, and persistence impact.
3. Keep transport thin and keep behavior near the slice.
4. Make validation, expected failure paths, authorization, and migrations explicit.
5. If the task touches Minimal APIs, route groups, HTTP result mapping, or OpenAPI, load the Minimal API reference.
6. If the task adds or reshapes commands, queries, handlers, or MediatR slices, load the CQRS slice reference.
7. If modernization or version-sensitive work is involved, load the platform baseline reference before recommending upgrades.
8. Run the most relevant verification for the touched backend surface.

## Required checklist

For every meaningful backend change, reason through:

- slice or feature affected;
- command or query semantics;
- endpoint and route behavior;
- request and response contracts;
- validation rules;
- expected business errors;
- authorization and ownership checks;
- persistence impact;
- migration impact;
- caller impact.

## Reference files

Load only the references that apply:

- [dotnet-minimal-api.md](references/dotnet-minimal-api.md)
  Covers Minimal API endpoint structure, route groups, `IEndpoint` registration, result mapping, `ProblemDetails`, and OpenAPI expectations.
- [dotnet-cqrs-slice.md](references/dotnet-cqrs-slice.md)
  Covers CQRS/MediatR slice structure, request shapes, handler rules, and query/command boundaries.
- [dotnet-vertical-slice.md](references/dotnet-vertical-slice.md)
  Explains slice structure, file responsibilities, contract boundaries, and version-discipline expectations.
- [dotnet-validation-and-errors.md](references/dotnet-validation-and-errors.md)
  Covers request validation, business validation, expected failure modeling, and HTTP response consistency.
- [dotnet-migrations-project.md](references/dotnet-migrations-project.md)
  Covers dedicated EF Core migrations projects, migration quality, and persistence-change checks.
- [dotnet-platform-baseline.md](references/dotnet-platform-baseline.md)
  Provides the current stable .NET modernization baseline and upgrade review checklist.

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
