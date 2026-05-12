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

Use request validators for:

- required fields;
- lengths and formats;
- basic cross-field checks;
- syntactic correctness.

Keep these rules near the slice.

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

- Prefer the repo's stable, supported validation and error stack.
- Do not introduce preview packages or framework-only features unless the request explicitly calls for them.
- When a change depends on runtime or framework capabilities, verify that the target version is supported and stable before baking that assumption into the contract.

## Reporting expectations

Plans and implementations should mention:

- validation changes;
- newly introduced error cases;
- impacted API responses;
- any frontend consequences from new errors.

## Red flags

- Empty `catch` blocks or broad exception swallowing.
- Returning `500` for expected user mistakes.
- Returning persistence entities directly and leaking internals.
- Hiding business invariants in frontend-only logic.
- Adding endpoints without describing invalid-path behavior.
- Returning inconsistent status codes for the same failure class across related endpoints.
