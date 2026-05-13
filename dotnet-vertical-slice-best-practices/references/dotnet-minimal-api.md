# .NET Minimal API

Use this reference when the task changes the HTTP edge of the backend:

- new Minimal API endpoints;
- route groups;
- `IEndpoint` registration;
- route-level authorization;
- typed HTTP result mapping;
- `ProblemDetails`;
- OpenAPI exposure for Minimal APIs.

## Endpoint structure

- Organize endpoints in the `Api` layer.
- Use endpoint classes implementing `IEndpoint`.
- Group routes by aggregate or resource.
- Keep endpoint lambdas thin: receive input, call `ISender`, and map the result.
- Keep business rules out of endpoints.

Preferred style:

```csharp
public sealed class CustomersEndpoints : IEndpoint
{
    public void Map(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v1/customers")
            .RequireAuthorization();

        group.MapPost("/", async (
            ISender sender,
            [FromBody] CreateCustomerCommand command,
            CancellationToken cancellationToken) =>
                (await sender.Send(command, cancellationToken)).ToCreatedResult("/api/v1/customers/..."));
    }
}
```

## HTTP mapping rules

- Map expected application errors consistently to typed HTTP responses.
- Use shared result-mapping extensions where possible.
- Use `ProblemDetails` for error payloads.
- Include trace and correlation data in problem payloads when the repo already supports it.
- Keep route-level authorization in `Api` unless a rule is truly use-case-specific.

## Registration rules

- Register `IEndpoint` implementations once.
- Map them centrally.
- Avoid ad hoc endpoint registration patterns that fragment the API surface.

## OpenAPI rules

- Prefer the official Microsoft package: `Microsoft.AspNetCore.OpenApi`.
- Do not add Swagger or Swashbuckle packages unless the user explicitly requests an exception.
- Register OpenAPI centrally in `Program.cs`.
- Expose the OpenAPI document with `MapOpenApi()` for non-production environments by default.
- Keep endpoint metadata accurate so the generated document stays useful.

## Avoid

- Controllers when the repo standard is Minimal APIs.
- Fat endpoint lambdas.
- Direct `DbContext` usage inside endpoints.
- Ad hoc anonymous error objects instead of `ProblemDetails`.
- Adding Swagger or Swashbuckle as the default OpenAPI path.
