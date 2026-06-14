# .NET Testing

Use this reference whenever a backend change adds or modifies behavior that should be verified by
automated tests. Vertical slices are highly testable; when tests are in scope, a healthy slice ships
with tests that match its intent.

## Tests are opt-in (default: do not create tests)

Do **not** create or scaffold tests unless the user explicitly asks for them. The default behavior is
to implement the slice without tests. This applies even when the change clearly *could* be tested.

- If tests are not requested, do not add test projects, test files, or test dependencies, and do not
  modify CI to run tests.
- It is fine to *mention* in the summary that the change is testable and to note what a test would
  cover, but stop short of writing tests.
- Only when the user explicitly requests tests (or the repo's task clearly includes them) follow the
  guidance below.

## Test layers

Match the test to the kind of logic, and prefer the cheapest layer that gives real confidence:

- **Unit tests** for pure decision logic: validators, domain rules, and handler branches that do not
  need a real database. Fast, many.
- **Integration tests** for the slice end to end: HTTP request -> validation -> handler ->
  persistence -> HTTP response. These catch contract, mapping, and EF Core issues that unit tests
  miss. Fewer, higher value.
- Avoid testing EF Core against the in-memory provider as a substitute for a relational database; it
  does not enforce relational behavior (constraints, transactions, concurrency, SQL translation) and
  gives false confidence.

## Integration testing shape

- Drive the API through `WebApplicationFactory<T>` so the real DI graph, middleware, validation
  pipeline, and endpoint mapping are exercised.
- Run against a real PostgreSQL using **Testcontainers** (`Testcontainers.PostgreSql`) so the database
  matches production behavior. Apply migrations (or the migrator) on startup, then assert real SQL
  outcomes.
- Override only what must be replaced for the test (external integrations, clock, auth), not the
  database under test.
- For state isolation between tests, prefer **Respawn** to reset the database to a known baseline
  between tests, rather than tearing down and recreating the container each time.
- Assert the full contract: status code, `ProblemDetails` shape for failures, and the response body
  for success. These are the contracts callers depend on.

## What every slice test should cover

For a new or changed slice, verify:

1. the happy path returns the expected typed result and status code;
2. invalid input returns `400` with `ProblemDetails` and does **not** execute business work;
3. each expected business error (not found, conflict, forbidden) maps to its agreed status code;
4. authorization and ownership checks actually block unauthorized callers;
5. persistence side effects happened (or did not) as intended, read back from the database.

## Conventions

- Keep tests close to the slice's intent and name them after behavior, not implementation.
- Reuse a shared test fixture for the container and factory so the database spins up once per run,
  not once per test.
- Seed only the data a test needs; prefer per-test isolation (transaction rollback or unique data)
  over a shared mutable dataset.
- Treat a failing or flaky migration in a test run as a real defect, not a test-environment quirk.

## Reporting expectations

Plans and implementations should state:

- which slices gained or changed tests;
- whether the invalid-input path was verified to return `400` + `ProblemDetails` before business work;
- whether integration coverage runs against a real PostgreSQL or only unit-level logic.

## Red flags

- New behavior with no test, or only a happy-path test.
- Integration tests that assert against mocks instead of the real database for persistence claims.
- Using the EF Core in-memory provider to validate relational behavior.
- Tests coupled to internal implementation details that break on safe refactors.
