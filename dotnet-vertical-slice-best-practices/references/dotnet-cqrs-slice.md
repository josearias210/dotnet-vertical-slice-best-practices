# .NET CQRS Slice

Use this reference when the task creates or changes an application slice built with Vertical Slice Architecture, CQRS, and the source-generated `Mediator` dispatch abstraction described below.

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
- All requests go through the `ISender` dispatch abstraction, so endpoints stay thin and
  cross-cutting behaviors compose in one pipeline.
- Keep each handler focused on one use case.
- Do not move shared business logic into a fake service too early.

## Mediator: source-generated `Mediator`, not MediatR

Do not take a dependency on `MediatR` (it moved to commercial licensing in 2024–2025, with a paid
license required above a revenue threshold). This skill uses the free, source-generated **`Mediator`
package (martinothamar/Mediator)** as the default. It exposes a MediatR-compatible surface
(`IRequest<T>`, `IRequestHandler<,>`, `ISender`, `IPipelineBehavior<,>`) but resolves everything at
compile time via a source generator — no runtime reflection, no assembly scanning, AOT-friendly, and
no licensing cost.

```csharp
// A command and its handler, using the source-generated Mediator package
public sealed record CreateCustomerCommand(string Name) : IRequest<ErrorOr<CustomerResponse>>;

public sealed class CreateCustomerCommandHandler(IApplicationDbContext db)
    : IRequestHandler<CreateCustomerCommand, ErrorOr<CustomerResponse>>
{
    public async ValueTask<ErrorOr<CustomerResponse>> Handle(
        CreateCustomerCommand request, CancellationToken cancellationToken)
    {
        // ... use case logic, returns ErrorOr<CustomerResponse>
    }
}
```

Endpoints depend only on `ISender`, so handlers stay reachable without referencing the package's
concrete dispatcher. If a project needs zero third-party dependencies, a **small first-party
abstraction** (the same four interfaces plus one DI-resolved dispatcher) is a valid fallback that
keeps handler signatures identical — swapping between the two is mechanical.

## Pipeline behaviors (cross-cutting integrations)

Cross-cutting concerns — validation, logging/tracing, transactions, and integration hooks — live in
`IPipelineBehavior<TRequest, TResponse>` implementations, which the `Mediator` source generator wires
into the dispatch pipeline:

```csharp
public sealed class ValidationBehavior<TRequest, TResponse>(IEnumerable<IValidator<TRequest>> validators)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    public async ValueTask<TResponse> Handle(
        TRequest request, MessageHandlerDelegate<TRequest, TResponse> next, CancellationToken cancellationToken)
    {
        // run the slice's fluent validators; short-circuit with a failure result if invalid,
        // otherwise call next(request, cancellationToken)
    }
}
```

(If you use the first-party fallback instead, define an equivalent `IPipelineBehavior<,>` with a
`RequestHandlerDelegate<TResponse> next` and have the dispatcher compose registrations in order.)

Guidance for the pipeline:

- Register behaviors in a deliberate, documented order. A typical order is
  validation -> logging/tracing -> transaction/unit-of-work -> handler.
- Put **validation** in a behavior that runs the slice's fluent validator and returns the failure
  result (for example `ErrorOr` validation errors) before the handler executes.
- Put **integration concerns** (transactions, outbox/event dispatch, idempotency) in behaviors, not
  scattered inside handlers. This is the structured replacement for the MediatR pipeline that was
  previously used for those integrations.
- Keep behaviors generic and slice-agnostic; anything use-case-specific belongs in the handler.
- A behavior that must target only some requests should opt in via a marker interface on the request
  (for example `ITransactionalRequest`), not via type sniffing.

## Request rules

- Prefer `sealed record` or `sealed record class` for requests when practical.
- Use explicit response DTOs for query results and create flows.
- Use mutable request classes only when binding or local conventions clearly require them.

## Handler rules

- Inject only what the use case needs.
- Prefer `IApplicationDbContext` and narrow application abstractions.
- For caller identity, inject `ICurrentUser` (or the repo's equivalent), never `IHttpContextAccessor`
  or `HttpContext`. The `Application` layer stays transport-free. See `dotnet-security.md`.
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
