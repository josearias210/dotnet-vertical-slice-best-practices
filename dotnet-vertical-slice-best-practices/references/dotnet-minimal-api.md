# .NET Minimal API

Use this reference when the task changes the HTTP edge of the backend:

- new Minimal API endpoints;
- route groups;
- `IEndpoint` registration;
- route-level authorization;
- typed HTTP result mapping;
- `ProblemDetails`;
- OpenAPI exposure for Minimal APIs.
- health endpoints and readiness/liveness behavior;
- fluent request validation behavior.

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
- Include trace and correlation data in problem payloads when the repo supports it; for new
  .NET 10 AppHost work, prefer configuring `AddProblemDetails(options =>
  options.CustomizeProblemDetails = ...)` centrally with `traceId`, `activityId`, and an incoming
  correlation header such as `X-Correlation-ID`.
- Keep route-level authorization in `Api` unless a rule is truly use-case-specific.

## Validation rules

- Use fluent validation rules for request validation. Prefer a validator class near the slice
  (`{UseCase}CommandValidator`) with an explicit fluent/rule-builder API.
- Keep endpoint lambdas thin: they should call validation plumbing or send the request, not contain
  validation logic inline.
- Do not use `DataAnnotations` attributes on request DTOs or commands as the validation strategy.
- Do not add `Microsoft.Extensions.Validation` / `AddValidation()` as the default path when it would
  push the project toward attribute-based validation.
- If early transport validation is needed before `ISender`, use an endpoint filter or pipeline
  behavior that invokes the same fluent validator and returns `Results.ValidationProblem(...)`.
- Keep business validation in the slice/handler even when transport validation exists.
- Verify invalid HTTP requests return `400` with `ProblemDetails` and do not execute business work.

## Registration rules

- Register `IEndpoint` implementations once.
- Map them centrally.
- Avoid ad hoc endpoint registration patterns that fragment the API surface.

## OpenAPI rules

- Prefer the official Microsoft package: `Microsoft.AspNetCore.OpenApi`.
- Do not add Swagger or Swashbuckle packages unless the user explicitly requests an exception.
- Register OpenAPI centrally in `Program.cs`.
- Expose the OpenAPI document with `MapOpenApi()` for non-production environments by default.
- For .NET 10 projects that need CI artifacts or contract review, enable build-time OpenAPI
  generation with `OpenApiGenerateDocuments` and `Microsoft.Extensions.ApiDescription.Server`.
- Verify the actual generated file path in the repo. With current tooling it may be
  `obj/{ProjectName}.json`, not `obj/{Configuration}/{TargetFramework}/openapi/**/*.json`.
- Keep endpoint metadata accurate so the generated document stays useful.

## Health rules

- Prefer real ASP.NET Core health checks over hand-written health endpoints when introducing
  AppHost or containerized startup.
- Register health checks in `AppHost` with `AddHealthChecks()`.
- Map liveness and readiness separately, commonly `/health/live` and `/health/ready`.
- Include database readiness when PostgreSQL/EF Core is required to serve traffic, for example
  an EF Core DbContext health check tagged `ready`.
- It is acceptable to keep `/api/health` as a compatibility alias, but it should use the same
  health-check pipeline.

## Avoid

- Controllers when the repo standard is Minimal APIs.
- Fat endpoint lambdas.
- Direct `DbContext` usage inside endpoints.
- Ad hoc anonymous error objects instead of `ProblemDetails`.
- Adding Swagger or Swashbuckle as the default OpenAPI path.
- Leaving a manual health endpoint as the only container health signal.
