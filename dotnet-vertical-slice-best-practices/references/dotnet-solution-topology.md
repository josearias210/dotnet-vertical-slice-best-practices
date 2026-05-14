# .NET Solution Topology

Use this reference when work touches backend project boundaries, startup composition, container
builds, or shared MSBuild/NuGet defaults.

## Core rule

Keep the executable composition root separate from the transport layer.

Preserve local naming, but prefer a shape like:

```text
src/
  App.AppHost/
  App.Api/
  App.Application/
  App.Domain/
  App.Infrastructure/
  App.DbMigrator/
  Directory.Build.props
  Directory.Packages.props
```

## Project responsibilities

- `AppHost`
  - owns `Program.cs`;
  - composes dependency injection, auth, CORS, OpenAPI, middleware, health endpoints, and environment-specific startup behavior;
  - acts as the usual EF Core startup project when tooling needs runtime configuration.

- `Api`
  - owns endpoint groups, endpoint registration, transport-specific helpers, and HTTP response mapping;
  - stays endpoint-focused;
  - should not become the executable host or composition root.

- `Application`
  - owns use-case slices, commands, queries, handlers, validators, DTOs, and application behaviors.

- `Domain`
  - owns entities, enums, and domain concepts that should not depend on transport or infrastructure.

- `Infrastructure`
  - owns EF Core `DbContext`, configurations, external integrations, and concrete service wiring.

- `DbMigrator`
  - owns explicit schema-application execution;
  - reuses the same infrastructure registration and configuration model as the app host.

## AppHost and Api boundary

Prefer this dependency direction:

```text
AppHost -> Api
AppHost -> Application
AppHost -> Infrastructure
Api -> Application
Infrastructure -> Application or Domain as required by the repo
Application -> Domain
```

Review for these conditions:

1. Startup and hosting concerns stay in `AppHost`.
2. `Api` remains a class library or endpoint-focused transport project.
3. Feature endpoint mapping can evolve without reshaping application composition.
4. EF tooling uses the intended startup project instead of guessing.

## Shared build defaults

Use `Directory.Build.props` for solution-wide build conventions that should remain consistent across
projects, for example:

- `TargetFramework`;
- `Nullable`;
- `ImplicitUsings`;
- analyzer or warning defaults when the repo standardizes them centrally.

Use `Directory.Packages.props` for central package version management:

- set `ManagePackageVersionsCentrally` once;
- keep versions in `PackageVersion` items;
- omit per-project `Version` attributes from `PackageReference` entries unless the repo has a deliberate exception.

Do not scatter these values across every `.csproj` when the solution already centralizes them.

Use `global.json` when a repo targets a modern .NET line such as .NET 10 and the build should be
consistent across local development, CI, and Docker. Prefer copying `global.json` into Docker
restore layers together with `Directory.Build.props`, `Directory.Packages.props`, and the solution
file.

## Container and restore expectations

When Dockerfiles restore individual projects:

1. copy `Directory.Build.props`, `Directory.Packages.props`, `global.json` when present, and the
   solution file before `dotnet restore`;
2. copy the solution file and relevant `.csproj` files before restore to preserve cache efficiency;
3. copy source files after restore;
4. publish the executable project (`AppHost` or `DbMigrator`) explicitly.

If those central props files are omitted from the restore layer, container builds may diverge from
local builds or miss centrally-managed package data.

## Compose expectation

When the repo introduces `DbMigrator`, containerized local startup, or a Docker-based backend
developer workflow, create or update `compose.yml`.

The Compose file should:

- define the database service and its healthcheck;
- define the migrator service when schema setup is externalized;
- make the migrator depend on a healthy database;
- make the API or app host depend on successful migrator completion when both run in Compose;
- keep the default `docker compose up` path useful for a new contributor.

## Checklist for solution-level changes

- Does the repo already use `AppHost` and `Api` as separate concerns?
- Is new startup behavior landing in `AppHost`, not in the transport project?
- Are new projects covered by central build and package conventions?
- Do Dockerfiles copy central props before restore?
- Does `compose.yml` exist or get updated when the local backend workflow depends on containers?
- Do migration commands use the intended startup project?
- Is the explicit migrator still aligned with the host's configuration model?

## Red flags

- `Api` owns both endpoint mapping and all startup composition without a clear repo precedent.
- New projects restate target framework and shared compiler settings inconsistently.
- Package versions drift across `.csproj` files despite central package management.
- Dockerfiles restore without copying central props files or `global.json` first.
- A dedicated migrator exists, but the local Compose workflow does not run it.
- Migration tooling points at an incidental executable instead of the intentional host.
