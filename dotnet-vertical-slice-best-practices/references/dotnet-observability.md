# .NET Observability

Use this reference whenever a backend change touches logging, tracing, metrics, or telemetry export.
Logging is mandatory and standardized on this stack; do not introduce a different logging provider.

## Core rule

**Serilog is the mandatory logging provider.** All application logging goes through `ILogger<T>` with
Serilog configured as the provider at the host (`AppHost`). Configure it once, in composition, not per
feature.

- **Console output is the default sink and is always enabled.** Every environment writes structured
  logs to the console.
- **When OpenTelemetry is used, logs are also exported to the OpenTelemetry collector — and that
  export goes *through Serilog*** via the Serilog OTLP sink (`Serilog.Sinks.OpenTelemetry`). Do not
  wire a second logging pipeline through the OpenTelemetry logging provider; Serilog owns log export
  so there is a single, consistent log path.
- Traces and metrics still use the OpenTelemetry SDK directly (they are not Serilog's concern); only
  **logs** flow to the collector through Serilog.

## Application code

- Inject and use `ILogger<T>`; never `Console.WriteLine`.
- Prefer message templates with structured properties (`logger.LogInformation("Created {CustomerId}", id)`),
  not string interpolation, so properties stay queryable.
- For hot paths, `[LoggerMessage]` source-generated logging is encouraged — it still flows through
  Serilog, since Serilog is the provider behind `ILogger`.
- Keep application/handler code free of sink or transport concerns; it logs against the abstraction.

## Host configuration

Configure Serilog as the provider in the host. Console is unconditional; the OTLP sink is added when
OpenTelemetry is enabled:

```csharp
builder.Services.AddSerilog((services, lc) => lc
    .ReadFrom.Configuration(builder.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console());                       // default sink, always on

if (openTelemetryEnabled)
{
    builder.Services.AddSerilog((services, lc) => lc
        .WriteTo.OpenTelemetry(options =>      // logs -> collector, through Serilog
        {
            options.Endpoint = otlpEndpoint;   // e.g. http://otel-collector:4317
            options.Protocol = OtlpProtocol.Grpc;
            options.ResourceAttributes = new Dictionary<string, object>
            {
                ["service.name"] = serviceName // must match the OTel SDK resource below
            };
        }));
}
```

The Serilog OTLP sink automatically attaches `TraceId` and `SpanId` from the current `Activity`, so
exported logs correlate with traces in the collector. Keep `service.name` identical between the
Serilog OTLP sink and the OpenTelemetry SDK resource so logs and traces line up.

## Tracing and metrics (OpenTelemetry SDK)

Traces and metrics are wired through the OpenTelemetry SDK — **not** logs:

```csharp
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService(serviceName))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddNpgsql()
        .AddOtlpExporter(o => o.Endpoint = otlpEndpoint))
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddRuntimeInstrumentation()
        .AddOtlpExporter(o => o.Endpoint = otlpEndpoint));
// Do NOT add .WithLogging()/the OTel logging provider for log export — Serilog's OTLP sink owns logs.
```

## Conventions

- Use a Serilog bootstrap logger (`CreateBootstrapLogger()`) so failures during startup are captured
  before full configuration is read.
- Enable `UseSerilogRequestLogging()` for concise, structured HTTP request logs instead of the default
  verbose per-request framework logs.
- Read sink levels and overrides from configuration (`ReadFrom.Configuration`) so log levels are tunable
  per environment without code changes.
- Align correlation identifiers with the API's `ProblemDetails` metadata (`traceId`/`activityId`; see
  `dotnet-minimal-api.md`) so a failing response can be traced to its logs.

## Red flags

- A logging provider other than Serilog, or `Console.WriteLine` used for diagnostics.
- Logs exported to the collector through the OpenTelemetry logging provider instead of Serilog
  (double pipelines or an inconsistent log path).
- Mismatched `service.name` between logs and traces, breaking correlation.
- String-interpolated log messages that destroy structured properties.
- Sink/transport configuration leaking into application or handler code.
