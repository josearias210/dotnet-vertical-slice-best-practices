# dotnet-vertical-slice-best-practices

[![skills.sh](https://skills.sh/b/josearias210/dotnet-vertical-slice-best-practices)](https://skills.sh/josearias210/dotnet-vertical-slice-best-practices)
[![Validate Skills](https://github.com/josearias210/dotnet-vertical-slice-best-practices/actions/workflows/validate-skills.yml/badge.svg)](https://github.com/josearias210/dotnet-vertical-slice-best-practices/actions/workflows/validate-skills.yml)

An Agent Skill that teaches your AI coding assistant how to implement and evolve **.NET 10 / C# 14**
backends using vertical slice architecture — with a free source-generated mediator and pipeline,
explicit fluent validation, error handling, PostgreSQL persistence, dedicated EF Core 10 migrations,
and solution-level composition guidance for production-ready backends.

## The opinionated stack

This skill encodes one coherent, current set of choices for a .NET 10 backend. Every dependency is
free and license-clean; commercially relicensed packages (MediatR, AutoMapper, MassTransit) are
deliberately avoided.

| Concern | Choice |
|---|---|
| Runtime / language | .NET 10 (LTS) / C# 14, current idioms (file-scoped namespaces, primary constructors) |
| Architecture | Vertical slice + CQRS |
| Dispatch | Source-generated `Mediator` (martinothamar) — never MediatR |
| Validation | Fluent validators in a pipeline behavior |
| Errors | `ErrorOr<T>` → `ProblemDetails`, with typed `Results<>` unions |
| Persistence | EF Core 10 + PostgreSQL (Npgsql), dedicated migrations project |
| API docs | `Microsoft.AspNetCore.OpenApi` + Scalar UI (no Swashbuckle) |
| Composition | Separate host and transport (`Api`) projects, central package management |
| Resilience | `Microsoft.Extensions.Http.Resilience` (Polly v8) for outbound HTTP |
| Tests (opt-in) | `WebApplicationFactory` + Testcontainers + Respawn |

## What is an Agent Skill?

An Agent Skill is a portable folder of instructions that your AI coding assistant loads on demand.
It follows the open [Agent Skills](https://agentskills.io/) standard, which means it works across
all compatible tools: GitHub Copilot, Claude Code, Cursor, Windsurf, Codex, and many more.

When you ask your agent to create a new feature, add an endpoint, or handle a migration, this skill
activates automatically and guides it through the right patterns for your .NET 10 backend.

## What does this skill do?

Once installed, your coding assistant will:

- Structure each feature as a self-contained vertical slice (command/query + handler + contract + persistence)
- Keep Minimal API endpoints thin, grouped, and consistently mapped to typed HTTP results
- Apply CQRS slice conventions when creating commands, queries, and handlers, dispatched through the free source-generated `Mediator` package (never MediatR; first-party fallback) with a pipeline-behavior scheme for cross-cutting integrations
- Apply explicit validation and model expected business errors properly
- Create and validate EF Core migrations in the persistence layer, with a dedicated migrator executable when schema application is externalized
- Use explicit migration runners when schema application should be decoupled from API startup
- Create or update `compose.yml` when containerized local startup should run dependencies and migrations together
- Keep executable hosting (`AppHost`) separate from transport-focused endpoint projects (`Api`)
- Centralize shared MSBuild and NuGet defaults with `Directory.Build.props` and `Directory.Packages.props`
- Add and upgrade NuGet dependencies through centralized package management instead of scattered inline versions
- Keep deployable GitHub Actions image builds on merges to `main`, emitting matched backend and migrator image versions
- Preserve stable API contracts and avoid breaking caller behavior
- Check authorization, ownership, and persistence impact on every backend change
- Pin everything to the .NET 10 / C# 14 baseline and apply current idioms (file-scoped namespaces, primary constructors, no underscore-prefixed fields)

The skill ships eleven internal reference files that the agent loads on demand, grouped by concern:

**Feature slices & API edge**

| Reference | Purpose |
|---|---|
| `dotnet-vertical-slice.md` | Slice structure, file responsibilities, contract boundaries, when to split |
| `dotnet-cqrs-slice.md` | CQRS slice structure, source-generated `Mediator` (`ISender`) and pipeline behaviors, handlers, command/query boundaries |
| `dotnet-minimal-api.md` | Minimal API endpoints, route groups, typed result mapping, `ProblemDetails`, OpenAPI + Scalar |
| `dotnet-validation-and-errors.md` | Request validation, business errors, `ErrorOr` → `ProblemDetails` mapping |
| `dotnet-security.md` | Authentication, authorization, ownership, the `ICurrentUser` pattern, secrets, transport hardening |
| `dotnet-slice-example.md` | Complete end-to-end worked slice: entity, command, validator, handler, behavior, EF config, endpoint, migration |

**Persistence**

| Reference | Purpose |
|---|---|
| `dotnet-migrations-project.md` | Infrastructure-owned EF Core migrations, explicit migrator/bundle patterns, Compose ordering, entity configuration |

**Solution & platform**

| Reference | Purpose |
|---|---|
| `dotnet-solution-topology.md` | Host/`Api` separation, C# 14 coding conventions, `Directory.Build.props`, `Directory.Packages.props`, container restore |
| `dotnet-platform-baseline.md` | Fixed .NET 10 / C# 14 baseline, current-idiom rules, baseline checks, dependency licensing |

**DevOps & quality**

| Reference | Purpose |
|---|---|
| `devops-github.md` | GitHub Actions main-branch build policy, backend/migrator image artifacts, shared image-tag versioning |
| `dotnet-testing.md` | Unit vs integration layering, `WebApplicationFactory`, Testcontainers, Respawn, slice test checklist (opt-in) |

## Install

Run this command in any project where you want to use the skill:

```sh
npx skills add josearias210/dotnet-vertical-slice-best-practices
```

The CLI detects which coding agents you have installed and places the skill in the right directory.
It works without installing anything globally — `npx` handles it.

### Supported agents

Works with any [Agent Skills-compatible](https://agentskills.io/clients) tool, including:

- GitHub Copilot
- Claude Code
- Cursor
- Windsurf
- OpenAI Codex
- And [many more](https://skills.sh/josearias210/dotnet-vertical-slice-best-practices)

### Non-interactive install (CI or scripted setup)

```sh
npx skills add josearias210/dotnet-vertical-slice-best-practices --yes
```

## How it works

1. **Discovery** — at startup, your agent reads the skill's `name` and `description` to know when it applies.
2. **Activation** — when your request touches a .NET 10 backend feature, endpoint, command, query, or migration, the agent loads the full `SKILL.md` instructions into context.
3. **Execution** — the agent follows the vertical slice workflow and loads only the reference files it needs for your specific change.

Nothing is injected into your codebase. The skill lives in your agent's skills directory and is used only at inference time.

## Changelog

Notable changes are tracked in [CHANGELOG.md](CHANGELOG.md). The version there matches
`metadata.version` in [`SKILL.md`](dotnet-vertical-slice-best-practices/SKILL.md), and tagged releases
are verified against it in CI.

## Staying current

The skill is authored guidance, not a scraped feed. The only perishable parts — .NET/EF Core support
windows, language versions, and dependency licensing — are isolated in
[`dotnet-platform-baseline.md`](dotnet-vertical-slice-best-practices/references/dotnet-platform-baseline.md),
which carries a `Last reviewed` date and a list of the authoritative sources to re-verify against.
When those facts change, that file (and the date) is what gets updated.

## Contributing

Issues and pull requests are welcome — bug reports, clearer wording, or a well-argued change to a
convention. If you disagree with an opinion the skill takes, open an issue with the reasoning; the
goal is a coherent, defensible .NET 10 baseline, not a catalog of every option.

## Author

Created and maintained by [Antonio Arias (@josearias210)](https://github.com/josearias210).
If this skill is useful to you, a star on the repository helps others find it.

## License

Released under the [MIT License](LICENSE).
