# .NET Platform Baseline

Use this reference when a task needs an explicit .NET support baseline before making a modernization recommendation.

## Review date

Last reviewed: 2026-05-12

## Current stable baseline

- Preferred modernization target for new platform work: `.NET 10` LTS.
- Preferred matching web stack: `ASP.NET Core 10`.
- Preferred matching ORM release when upgrading persisted applications: `EF Core 10`.
- Current language reference point for `.NET 10`: `C# 14`.

## Support position

- `.NET 10` is the current LTS line and is supported through November 2028.
- `.NET 9` remains supported through November 2026.
- `.NET 8` remains supported through November 2026.
- `EF Core 10` is an LTS release aligned to `.NET 10` and is supported through November 10, 2028.

## Decision rules

1. Preserve the consuming repository's current target framework when the task is not about modernization.
2. Prefer supported stable versions over previews.
3. Prefer the active LTS line for greenfield work or intentional modernization unless the repository has a concrete constraint.
4. Treat runtime, ASP.NET Core, EF Core, provider, and language-version upgrades as coordinated work, not isolated package bumps.
5. Verify official support status again whenever this baseline is reused after its review date has gone stale.

## Upgrade review checklist

- Does the target repository already support the proposed runtime?
- Are the SDK, ASP.NET Core dependencies, EF Core packages, database provider, and CI images compatible?
- Are there documented breaking changes that affect migrations, JSON behavior, validation, routing, OpenAPI, or generated SQL?
- Does the change require code updates, test updates, deployment updates, or database migration work?
- Should the work remain on the current supported version instead of upgrading now?
