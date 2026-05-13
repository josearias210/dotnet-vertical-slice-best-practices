# .NET Migrations Project

Use this reference whenever a backend change affects stored data.

## Core rule

Database schema changes must be represented through EF Core migrations in the dedicated migrations project, not ad hoc SQL sprinkled through the application.

Keep EF Core and provider choices aligned with the repo's target framework. When upgrade work is in
scope, prefer currently supported stable releases and confirm provider compatibility before changing
the migrations toolchain.

Load `dotnet-platform-baseline.md` when version or modernization guidance is relevant.

## Expected solution convention

Projects may vary by repo, but the standard intent is:

```text
src/
  App.Api/
  App.Infrastructure/
  App.Persistence/
  App.Migrations/
```

The exact names can differ. Preserve the repo's local names while keeping the same separation of concerns.

## Responsibilities

- Main persistence project:
  - owns `DbContext`;
  - owns entity configurations;
  - owns provider setup and persistence abstractions.

- Migrations project:
  - owns EF migrations;
  - owns model snapshots if applicable;
  - acts as the migration assembly target.

- Startup/API project:
  - provides runtime configuration when EF tooling needs it.

- Dedicated migrator executable:
  - reuses the same infrastructure registration as the runtime app;
  - loads the same effective configuration model;
  - applies schema changes explicitly outside normal request serving.

## Required checks when data changes

Ask:

1. Did an entity, property, enum persistence, constraint, relation, or index change?
2. Does EF mapping need adjustment?
3. Is a migration required?
4. Does the migration project configuration still point to the correct assembly?
5. Does the change need seed or update logic or just schema evolution?
6. Does the generated migration preserve existing data safely?
7. If a migrator executable exists, does it still apply the correct schema path?
8. If Compose orchestrates local startup, will database health and migration ordering still work?

## Common command pattern

Use repo-specific project names, but preserve this shape:

```bash
dotnet ef migrations add <MigrationName> \
  --project <MigrationsProject> \
  --startup-project <StartupProject> \
  --context <DbContextName>
```

```bash
dotnet ef database update \
  --project <MigrationsProject> \
  --startup-project <StartupProject> \
  --context <DbContextName>
```

If the repo uses a design-time factory, follow that convention instead of inventing a second path.

## Dedicated migration runner

For repos that want predictable deploys and local environment bootstrapping, prefer a dedicated
console or host project such as `App.DbMigrator`.

Expected behavior:

- build a host or service provider with the repo's normal configuration sources;
- register infrastructure once through the same extension used by the running app;
- resolve the real `DbContext` inside a scope;
- log which provider and migration path are being used;
- call `MigrateAsync()` for relational providers that use migrations;
- use provider-specific fallback behavior only when the repo intentionally supports it, such as
  `EnsureCreatedAsync()` for an SQLite-only local/test path.

Production-facing APIs should not silently become the default schema-mutation mechanism. If local
development intentionally enables auto-migration on app startup, keep that environment-scoped and
documented as a convenience, not as the deployment strategy.

## Docker Compose orchestration

When the backend uses Docker Compose for local infrastructure, create or update `compose.yml` with a
one-shot migrator service so `docker compose up` prepares the database before the API serves traffic.

If the task adds `App.DbMigrator`, adds containerized backend startup, or formalizes local developer
bootstrapping, treat Compose orchestration as part of the implementation unless the repo explicitly
uses another local orchestration standard.

Preferred shape:

```yaml
services:
  db:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app_local"]
      interval: 10s
      timeout: 5s
      retries: 5

  db-migrator:
    build:
      context: .
      dockerfile: backend/src/App.DbMigrator/Dockerfile
    depends_on:
      db:
        condition: service_healthy
    restart: "no"

  api:
    build:
      context: .
      dockerfile: backend/src/App.AppHost/Dockerfile
    depends_on:
      db-migrator:
        condition: service_completed_successfully
```

Adapt names and paths to the repository, but preserve the intent:

- database health is explicit;
- migrations run before dependent app services;
- the migrator exits successfully after applying schema changes;
- API startup is not forced to own migration execution;
- the compose file is part of the backend change, not an optional follow-up.

## Migration quality rules

- Name migrations after business intent, not timestamps.
- Keep one conceptual schema change per migration whenever practical.
- Add constraints and indexes intentionally, not as an afterthought.
- Watch nullability transitions and backfills.
- Avoid destructive data loss unless the requirement explicitly allows it.
- Treat enum and storage changes as migration-sensitive.
- Review generated migration code and snapshots instead of trusting scaffolding blindly.
- Prefer reversible operations when practical; if reversal is not realistic, say so explicitly.
- Separate schema evolution from large operational backfills when the repo's deployment model requires it.

## Reporting rule

Any plan or implementation touching persistence must state:

- whether a migration is required;
- whether it was created;
- where it lives;
- what schema behavior changed;
- how it is applied locally and in deployment when the repo uses an explicit migrator.

## Red flags

- Changed entity config with no migration discussion.
- Migration added in the API project by accident.
- Migration logic embedded only in API startup when the repo expects an explicit migrator.
- Direct SQL used where a normal EF migration should exist.
- No thought given to existing data after tightening nullability or uniqueness.
- Docker Compose starts the API before the database is healthy or before the migrator has completed.
- Upgrading EF Core or providers without checking support alignment for the repo's target framework.
