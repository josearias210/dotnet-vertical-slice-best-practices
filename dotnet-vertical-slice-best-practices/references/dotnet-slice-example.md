# .NET Slice Example (golden path)

Use this reference when you need a single, complete, end-to-end example of a healthy slice on this
skill's stack: .NET 10 / C# 14, the source-generated `Mediator`, FluentValidation, `ErrorOr`,
`TypedResults` with `Results<...>` unions, EF Core 10 + Npgsql, and a validation pipeline behavior.

This is the reference shape. Adapt names to the repo; keep the structure and the boundaries.

## Slice layout

```text
App.Domain/Customers/Customer.cs
App.Application/
  Abstractions/ICurrentUser.cs
  Abstractions/IApplicationDbContext.cs
  Behaviors/ValidationBehavior.cs
  Features/Customers/CreateCustomer/
    CreateCustomerCommand.cs
    CreateCustomerCommandValidator.cs
    CreateCustomerCommandHandler.cs
    CreateCustomerResponse.cs
App.Infrastructure/Persistence/Configurations/CustomerConfiguration.cs
App.Api/Features/Customers/CreateCustomerEndpoint.cs
```

## Domain entity

```csharp
namespace App.Domain.Customers;

public sealed class Customer
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = null!;
    public string Email { get; private set; } = null!;
    public Guid OwnerId { get; private set; }

    private Customer() { } // EF Core

    public static Customer Create(string name, string email, Guid ownerId) =>
        new() { Id = Guid.CreateVersion7(), Name = name, Email = email, OwnerId = ownerId };
}
```

`Guid.CreateVersion7()` gives time-ordered keys (index-friendly). Concurrency is handled in the
EF configuration via Npgsql `xmin`, so the entity needs no explicit version column.

## Command and response

```csharp
namespace App.Application.Features.Customers.CreateCustomer;

public sealed record CreateCustomerCommand(string Name, string Email)
    : IRequest<ErrorOr<CreateCustomerResponse>>;

public sealed record CreateCustomerResponse(Guid Id, string Name, string Email);
```

## Validator (transport-shape rules)

```csharp
namespace App.Application.Features.Customers.CreateCustomer;

public sealed class CreateCustomerCommandValidator : AbstractValidator<CreateCustomerCommand>
{
    public CreateCustomerCommandValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(320);
    }
}
```

## Handler (business rules + persistence + ownership)

```csharp
namespace App.Application.Features.Customers.CreateCustomer;

public sealed class CreateCustomerCommandHandler(IApplicationDbContext db, ICurrentUser currentUser)
    : IRequestHandler<CreateCustomerCommand, ErrorOr<CreateCustomerResponse>>
{
    public async ValueTask<ErrorOr<CreateCustomerResponse>> Handle(
        CreateCustomerCommand request, CancellationToken cancellationToken)
    {
        var emailTaken = await db.Customers
            .AsNoTracking()
            .AnyAsync(c => c.Email == request.Email, cancellationToken);

        if (emailTaken)
        {
            return Error.Conflict("Customer.DuplicateEmail", "A customer with this email already exists.");
        }

        var customer = Customer.Create(request.Name, request.Email, currentUser.Id);
        db.Customers.Add(customer);
        await db.SaveChangesAsync(cancellationToken);

        return new CreateCustomerResponse(customer.Id, customer.Name, customer.Email);
    }
}
```

The handler depends on `ICurrentUser`, never on `HttpContext` (see `dotnet-security.md`). Expected
failures are `ErrorOr` values, not exceptions.

## Validation pipeline behavior

Transport-shape validation runs once, in a behavior, before any handler — not inline in endpoints:

```csharp
namespace App.Application.Behaviors;

public sealed class ValidationBehavior<TRequest, TResponse>(IEnumerable<IValidator<TRequest>> validators)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
    where TResponse : IErrorOr
{
    public async ValueTask<TResponse> Handle(
        TRequest request, MessageHandlerDelegate<TRequest, TResponse> next, CancellationToken cancellationToken)
    {
        if (!validators.Any())
        {
            return await next(request, cancellationToken);
        }

        var context = new ValidationContext<TRequest>(request);
        var errors = validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f is not null)
            .Select(f => Error.Validation(f.PropertyName, f.ErrorMessage))
            .ToList();

        if (errors.Count == 0)
        {
            return await next(request, cancellationToken);
        }

        // ErrorOr<T> has an implicit conversion from List<Error>; the dynamic cast bridges the generic TResponse.
        return (dynamic)errors;
    }
}
```

## EF Core configuration

```csharp
namespace App.Infrastructure.Persistence.Configurations;

public sealed class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("customers");
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Name).HasMaxLength(200).IsRequired();
        builder.Property(c => c.Email).HasMaxLength(320).IsRequired();
        builder.HasIndex(c => c.Email).IsUnique();

        builder.UseXminAsConcurrencyToken(); // Npgsql optimistic concurrency, no extra column
    }
}
```

## Endpoint (thin transport, typed result union)

```csharp
namespace App.Api.Features.Customers;

public sealed class CreateCustomerEndpoint : IEndpoint
{
    public void Map(IEndpointRouteBuilder app) =>
        app.MapPost("api/v1/customers", Handle).RequireAuthorization();

    private static async Task<Results<Created<CreateCustomerResponse>, ValidationProblem, Conflict<ProblemDetails>>> Handle(
        CreateCustomerCommand command,
        ISender sender,
        CancellationToken cancellationToken)
    {
        var result = await sender.Send(command, cancellationToken);

        if (!result.IsError)
        {
            return TypedResults.Created($"/api/v1/customers/{result.Value.Id}", result.Value);
        }

        return result.FirstError.Type switch
        {
            ErrorType.Conflict => TypedResults.Conflict(new ProblemDetails { Title = result.FirstError.Description }),
            _ => TypedResults.ValidationProblem(
                result.Errors.ToDictionary(e => e.Code, e => new[] { e.Description })),
        };
    }
}
```

For endpoints with more outcomes, prefer the single shared `ErrorOr -> IResult` mapper in
`dotnet-validation-and-errors.md` instead of re-deriving status codes here.

## Composition (registration)

In the host (`AppHost`) wire the pieces once:

```csharp
builder.Services.AddMediator();                              // source-generated Mediator
builder.Services.AddValidatorsFromAssembly(applicationAssembly);
builder.Services.AddScoped(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
builder.Services.AddScoped<ICurrentUser, CurrentUser>();     // see dotnet-security.md
// register IEndpoint implementations and map them centrally (see dotnet-minimal-api.md)
```

## Migration

```bash
dotnet ef migrations add CreateCustomers \
  --project src/App.Migrations \
  --startup-project src/App.AppHost \
  --context AppDbContext
```

## Why this is the golden path

- one folder per use case; intent obvious from the name;
- endpoint is thin and returns a typed union that drives OpenAPI metadata;
- validation runs in one pipeline behavior, not scattered in endpoints;
- expected failures are `ErrorOr` values mapped to `ProblemDetails`, never exceptions;
- ownership uses `ICurrentUser`, not `HttpContext`, keeping `Application` transport-free;
- persistence impact is visible and concurrency is handled at the mapping layer.
