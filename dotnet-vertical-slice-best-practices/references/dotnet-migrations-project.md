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

## Required checks when data changes

Ask:

1. Did an entity, property, enum persistence, constraint, relation, or index change?
2. Does EF mapping need adjustment?
3. Is a migration required?
4. Does the migration project configuration still point to the correct assembly?
5. Does the change need seed or update logic or just schema evolution?
6. Does the generated migration preserve existing data safely?

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
- what schema behavior changed.

## Red flags

- Changed entity config with no migration discussion.
- Migration added in the API project by accident.
- Direct SQL used where a normal EF migration should exist.
- No thought given to existing data after tightening nullability or uniqueness.
- Upgrading EF Core or providers without checking support alignment for the repo's target framework.
