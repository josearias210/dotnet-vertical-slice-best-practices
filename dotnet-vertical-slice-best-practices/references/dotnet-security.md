# .NET Security

Use this reference when a backend change touches authentication, authorization, ownership, user
identity, secrets, or transport hardening. Security belongs in the backend flow; never rely on
frontend discipline to enforce it.

## Authentication

- Authenticate at the edge (commonly JWT bearer) and apply `RequireAuthorization()` at the route
  group, opening up anonymous routes explicitly rather than the reverse.
- Keep token configuration and scheme wiring in the host (`AppHost`), not in feature slices.

## Current user context (do not touch `HttpContext` in Application)

The `Application` layer must stay transport-free. Do not inject `IHttpContextAccessor` into handlers.
Define a narrow abstraction in `Application` and implement it at the edge:

```csharp
// App.Application/Abstractions/ICurrentUser.cs
namespace App.Application.Abstractions;

public interface ICurrentUser
{
    Guid Id { get; }
    bool IsAuthenticated { get; }
    bool IsInRole(string role);
}
```

```csharp
// App.Api (or Infrastructure): the only place that reads HttpContext
public sealed class CurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    private ClaimsPrincipal? User => accessor.HttpContext?.User;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated ?? false;
    public Guid Id => Guid.Parse(User?.FindFirstValue(ClaimTypes.NameIdentifier)
                                 ?? throw new InvalidOperationException("No authenticated user."));
    public bool IsInRole(string role) => User?.IsInRole(role) ?? false;
}
```

Handlers depend on `ICurrentUser`. This keeps the use case testable and free of transport types.

## Authorization and ownership

Authentication proves who the caller is; authorization decides what they may do. Two complementary
mechanisms:

- **Policy / role checks** for coarse access — express them as authorization policies applied to
  route groups in the host.
- **Resource-based / ownership checks** for "may this user act on *this* record" — these are business
  decisions and belong in the slice. Either use ASP.NET Core `IAuthorizationService` with a resource
  handler, or check ownership in the handler against `ICurrentUser`:

```csharp
var order = await db.Orders.FirstOrDefaultAsync(o => o.Id == request.OrderId, cancellationToken);
if (order is null)
{
    return Error.NotFound("Order.NotFound", "Order not found.");
}
if (order.OwnerId != currentUser.Id)
{
    return Error.Forbidden("Order.Forbidden", "You do not own this order.");
}
```

`Forbidden` maps to `403`, `NotFound` to `404` (see `dotnet-validation-and-errors.md`). When existence
itself is sensitive, deliberately return `404` for an unowned resource to avoid leaking that it
exists, and document that choice.

## Secrets and configuration

- Never commit secrets to `appsettings.json`. Use user-secrets in local development and a real secret
  store / environment variables in deployed environments.
- Validate configuration at startup with the options pattern (`ValidateOnStart`) so a missing or
  malformed secret fails fast instead of at first use.

## Transport hardening

- Enable HTTPS redirection and HSTS for deployed environments.
- Configure CORS with an explicit allow-list; never combine `AllowAnyOrigin` with credentials.
- Apply rate limiting on public or expensive endpoints (`AddRateLimiter`; see `dotnet-minimal-api.md`).
- Send sensible security response headers (for example a restrictive `Content-Security-Policy` for
  any served HTML, `X-Content-Type-Options: nosniff`).

## Contract safety

- Bind dedicated command/request types, never persistence entities, which prevents over-posting /
  mass-assignment.
- Return dedicated response DTOs; do not leak entity internals or database-shaped data.
- Keep error messages specific enough to be useful without exposing internal implementation detail.

## Red flags

- `IHttpContextAccessor` injected into application handlers.
- Ownership enforced only in the frontend or only by hiding UI controls.
- Validation used as a stand-in for authorization (shape checks are not identity checks).
- Secrets in `appsettings.json` or committed configuration.
- `AllowAnyOrigin` together with `AllowCredentials`.
- Returning entities directly from endpoints.
