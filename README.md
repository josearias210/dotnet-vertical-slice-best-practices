# dotnet-vertical-slice-best-practices

[![skills.sh](https://skills.sh/b/josearias210/dotnet-vertical-slice-best-practices)](https://skills.sh/josearias210/dotnet-vertical-slice-best-practices)
[![Validate Skills](https://github.com/josearias210/dotnet-vertical-slice-best-practices/actions/workflows/validate-skills.yml/badge.svg)](https://github.com/josearias210/dotnet-vertical-slice-best-practices/actions/workflows/validate-skills.yml)

An Agent Skill that teaches your AI coding assistant how to implement and evolve .NET backends
using vertical slice architecture — with explicit validation, error handling, PostgreSQL persistence,
and dedicated EF Core migrations.

## What is an Agent Skill?

An Agent Skill is a portable folder of instructions that your AI coding assistant loads on demand.
It follows the open [Agent Skills](https://agentskills.io/) standard, which means it works across
all compatible tools: GitHub Copilot, Claude Code, Cursor, Windsurf, Codex, and many more.

When you ask your agent to create a new feature, add an endpoint, or handle a migration, this skill
activates automatically and guides it through the right patterns for your .NET backend.

## What does this skill do?

Once installed, your coding assistant will:

- Structure each feature as a self-contained vertical slice (command/query + handler + contract + persistence)
- Keep Minimal API endpoints thin, grouped, and consistently mapped to typed HTTP results
- Apply CQRS and MediatR slice conventions when creating commands, queries, and handlers
- Apply explicit validation and model expected business errors properly
- Create and validate EF Core migrations in a dedicated migrations project
- Preserve stable API contracts and avoid breaking caller behavior
- Check authorization, ownership, and persistence impact on every backend change
- Consult a .NET platform baseline before recommending upgrades or modernization

The skill ships six internal reference files that the agent loads on demand:

| Reference | Purpose |
|---|---|
| `dotnet-minimal-api.md` | Minimal API endpoints, route groups, result mapping, `ProblemDetails`, OpenAPI |
| `dotnet-cqrs-slice.md` | CQRS/MediatR slice structure, handlers, request shapes, command/query boundaries |
| `dotnet-vertical-slice.md` | Slice structure, file responsibilities, contract boundaries |
| `dotnet-validation-and-errors.md` | Request validation, business errors, HTTP response consistency |
| `dotnet-migrations-project.md` | Dedicated EF Core migrations project, migration quality checks |
| `dotnet-platform-baseline.md` | Current stable .NET baseline and upgrade checklist |

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
2. **Activation** — when your request touches a .NET backend feature, endpoint, command, query, or migration, the agent loads the full `SKILL.md` instructions into context.
3. **Execution** — the agent follows the vertical slice workflow and loads only the reference files it needs for your specific change.

Nothing is injected into your codebase. The skill lives in your agent's skills directory and is used only at inference time.
