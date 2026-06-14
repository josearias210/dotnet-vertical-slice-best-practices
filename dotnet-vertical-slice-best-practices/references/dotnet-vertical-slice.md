# .NET Vertical Slice

Use this reference whenever backend work creates or changes application behavior.

## Architectural intent

Prefer feature-oriented slices over broad horizontal service layers.

Preserve the repo's established structure, but avoid adding new generic service layers when the
behavior can stay local to a use case.

Each slice should make it easy to answer:

- what request enters the system;
- what validation runs;
- what application behavior happens;
- what persistence is touched;
- what response leaves the system.

## Default slice shape

Adapt to the repo if it already has a local convention, but prefer a shape like:

```text
Features/
  Resource/
    CreateResource/
      Endpoint.cs
      Command.cs
      Validator.cs
      Handler.cs
      Response.cs
```

or, for reads:

```text
Features/
  Resource/
    GetResource/
      Endpoint.cs
      Query.cs
      Handler.cs
      Response.cs
```

## Responsibilities by file

- `Endpoint`
  - maps transport to application request;
  - stays thin;
  - returns typed and consistent results;
  - should not host business logic.

- `Command` / `Query`
  - captures intent of the use case;
  - avoids UI-shaped naming when a domain or action name is clearer.

- `Validator`
  - request validation only;
  - keeps rules explicit and close to the use case.

- `Handler`
  - orchestrates the use case;
  - coordinates persistence and domain decisions;
  - returns a predictable result model.

- `Response`
  - keeps outbound contracts intentional;
  - does not leak persistence entities directly.

## CQRS guidance

- Commands mutate state.
- Queries read state.
- Do not mix mutation and read semantics casually.
- If a command needs to return useful state, return a clear response contract rather than forcing a hidden second query.

## Locality rules

- Prefer co-locating code inside the slice when it serves only that use case.
- Extract shared abstractions only when at least two real slices need them.
- Avoid generic `Services/` dumping grounds.
- Avoid turning a vertical-slice backend back into layered CRUD by habit.

## Contracts and persistence

When changing a slice, also check:

- endpoint route and semantics;
- request and response contracts;
- validation and error contract;
- data model and persistence impact;
- migrations if persisted shape changes;
- impact on frontend or other callers.

If the slice is externally visible, keep transport contracts explicit and stable. Prefer dedicated
request and response types over directly exposing entities or database-oriented shapes.

## Security rule

Authorization and ownership checks belong in the use case flow. Do not rely on frontend discipline to protect backend behavior.

## Version discipline

- Author every slice against .NET 10 / C# 14; this is the skill's fixed baseline.
- Use current .NET 10 / C# 14 idioms (file-scoped namespaces, primary constructors, no underscore
  field prefixes) rather than older-style code.
- If the consuming repo is not yet on .NET 10, the correct move is to bring it to .NET 10, not to
  author slices against an older runtime.
- Load `dotnet-platform-baseline.md` for the exact baseline and current-idiom rules.

## When to split a slice

Split when one use case starts carrying multiple independent business intents, for example:

- one command performs create + publish + notify;
- a query returns unrelated views for multiple screens;
- validation rules diverge materially by scenario.

## Definition of a healthy slice

A new or changed slice is healthy when:

- its intent is obvious from the folder name;
- endpoint, request, handler, validator, and response remain coherent;
- persistence impact is visible;
- contract impact is explicit;
- authorization boundaries are visible;
- it does not introduce cross-feature leakage without reason.
