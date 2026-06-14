# .NET Validation And Errors

Use this reference whenever backend behavior accepts input, returns failures, or exposes an API contract.

## Guiding principles

- Validate early.
- Fail predictably.
- Keep transport responses consistent.
- Do not use exceptions for expected business outcomes.
- Make errors useful to both callers and future maintainers.
- Keep user-facing failures specific without leaking internal implementation detail.

## Validation layers

### 1. Request validation

Use fluent request validators for:

- required fields;
- lengths and formats;
- basic cross-field checks;
- syntactic correctness.

Keep these rules near the slice. Prefer a `{UseCase}CommandValidator` or `{UseCase}QueryValidator`
that expresses rules with a fluent API, similar in spirit to EF Core Fluent API for persistence
mapping.

Do not use `DataAnnotations` attributes on contracts as the validation strategy. Contracts should
stay transport/application messages; validation rules should remain explicit and discoverable in
validator classes.

For .NET 10 Minimal APIs, request-shape validation may happen before the handler through an endpoint
filter or pipeline behavior that invokes the slice validator. Preserve these boundaries:

- transport validation: required fields, string lengths, simple formats, malformed request shape;
- application validation: use-case rules, business-safe normalization, expected business errors.

In split `AppHost`/`Api` solutions, keep the validator in `Application` and call it from shared
validation plumbing instead of duplicating rules in endpoint attributes.

### 2. Business validation

Use application or domain logic for:

- ownership;
- duplicates;
- state transitions;
- invariant enforcement;
- existence checks when they are business-significant.

Do not hide business rules inside transport validators.

## Error model

Prefer a consistent result style such as `ErrorOr<T>` or the repo's established equivalent.

Expected outcomes should be modeled intentionally, for example:

- not found;
- conflict;
- forbidden;
- validation failed;
- unsupported transition.

Reserve exceptions for exceptional failures:

- infrastructure outages;
- corrupted invariants;
- genuinely unexpected conditions.

When the repo has a machine-readable error code convention, preserve it. If it does not, avoid
inventing ad hoc strings independently in each endpoint.

## HTTP response guidance

Endpoints should convert failures into clear HTTP responses, commonly through `ProblemDetails` or the repo's standardized mapper.

Callers should not need to reverse-engineer inconsistent status code behavior.

Keep category mapping predictable, for example:

- validation -> `400`;
- unauthenticated -> `401`;
- unauthorized -> `403`;
- missing resource -> `404`;
- conflict or invalid transition -> `409` when that is the local convention.

Reuse the repo's current contract if it already differs intentionally.

## Reference mapping (ErrorOr -> typed result)

Centralize the failure-to-HTTP mapping once so endpoints do not re-derive status codes. With
`ErrorOr<T>`, a shared extension keeps the union return types in `dotnet-minimal-api.md` honest:

```csharp
public static class ErrorMappingExtensions
{
    public static IResult ToProblemResult(this List<Error> errors)
    {
        if (errors.All(e => e.Type == ErrorType.Validation))
        {
            var failures = errors.ToDictionary(e => e.Code, e => new[] { e.Description });
            return TypedResults.ValidationProblem(failures);
        }

        var first = errors[0];
        var status = first.Type switch
        {
            ErrorType.NotFound   => StatusCodes.Status404NotFound,
            ErrorType.Conflict   => StatusCodes.Status409Conflict,
            ErrorType.Forbidden  => StatusCodes.Status403Forbidden,
            ErrorType.Unauthorized => StatusCodes.Status401Unauthorized,
            _                    => StatusCodes.Status400BadRequest,
        };

        return TypedResults.Problem(
            detail: first.Description,
            statusCode: status,
            // a machine-readable code aids callers without leaking internals
            extensions: new Dictionary<string, object?> { ["code"] = first.Code });
    }
}
```

Adapt the error type and codes to the repo's established result model. The point is one mapper, used
everywhere, producing `ProblemDetails` consistently — not a per-endpoint reinvention.

## Slice checklist

For every new or changed slice, ask:

1. What input can be invalid?
2. Which invalid states are expected business outcomes?
3. Which error codes or categories should the caller observe?
4. Which responses must be stable for frontend use?
5. Could any failure leak internal implementation detail?

## Security relation

Validation is not authorization.

Do not use shape validation as a substitute for:

- identity checks;
- ownership checks;
- permission checks.

## Version and API discipline

- Target the .NET 10 / C# 14 validation and error stack; this is the skill's fixed baseline.
- Keep request validation library-neutral (fluent request validators) so the contract is not bound
  to a single package's licensing or support trajectory.
- Do not introduce preview packages unless the request explicitly calls for them.

## Reporting expectations

Plans and implementations should mention:

- validation changes;
- newly introduced error cases;
- impacted API responses;
- any frontend consequences from new errors.
- whether invalid HTTP requests were verified to return `400` and `ProblemDetails` before business
  work executes.

## Red flags

- Empty `catch` blocks or broad exception swallowing.
- Returning `500` for expected user mistakes.
- Returning persistence entities directly and leaking internals.
- Hiding business invariants in frontend-only logic.
- Hiding validation rules in `DataAnnotations` attributes when the repo standard is fluent
  validation.
- Adding endpoints without describing invalid-path behavior.
- Returning inconsistent status codes for the same failure class across related endpoints.
