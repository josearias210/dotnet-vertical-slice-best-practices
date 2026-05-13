# .NET CQRS Slice

Use this reference when the task creates or changes an application slice built with Vertical Slice Architecture, CQRS, and MediatR.

## When to load this reference

Load it when the task involves:

- a new command;
- a new query;
- a new handler;
- a slice refactor;
- moving business logic out of endpoints.

## Slice structure

Prefer this shape inside `Application`:

```text
Features/
  {Aggregate}/
    {UseCase}/
      {UseCase}Command.cs
      {UseCase}CommandHandler.cs
      {UseCase}CommandValidator.cs
```

For reads:

```text
Features/
  {Aggregate}/
    Get{Thing}/
      Get{Thing}Query.cs
      Get{Thing}QueryHandler.cs
      Get{Thing}Response.cs
```

## Command and query rules

- Commands mutate state.
- Queries do not mutate state.
- All requests go through MediatR.
- Keep each handler focused on one use case.
- Do not move shared business logic into a fake service too early.

## Request rules

- Prefer `sealed record` or `sealed record class` for requests when practical.
- Use explicit response DTOs for query results and create flows.
- Use mutable request classes only when binding or local conventions clearly require them.

## Handler rules

- Inject only what the use case needs.
- Prefer `IApplicationDbContext` and narrow application abstractions.
- Use `AsNoTracking()` for read-only queries.
- Project to DTOs instead of loading full entities when possible.
- Use server-side filtering and projection deliberately.
- Return `ErrorOr<T>` for expected failures.
- Throw only for truly exceptional situations.

## Avoid

- Business logic in `Program.cs`.
- Business logic in endpoint lambdas.
- Generic repository layers over EF Core.
- Command handlers doing query-only work.
- Query handlers mutating state.
