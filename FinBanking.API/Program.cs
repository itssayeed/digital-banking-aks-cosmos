    using FinBanking.Api.DTOs;
    using FinBanking.Api.Services;
    using Microsoft.Azure.Cosmos;
    using Azure.Identity;
    using FinBanking.Api.Configuration;

    var builder = WebApplication.CreateBuilder(args);

    // ---------------------------------------------------------------
    // Key Vault – startup fail-fast configuration
    // ---------------------------------------------------------------
    KeyVaultConfigurationLoader? kvLoader = null;

    var keyVaultUri = Environment.GetEnvironmentVariable("KEYVAULT_URI");

    if (!string.IsNullOrWhiteSpace(keyVaultUri))
    {
        kvLoader = new KeyVaultConfigurationLoader(keyVaultUri);

        // Cosmos endpoint
        var cosmosEndpointFromKv =
            await kvLoader.GetRequiredSecretAsync("cosmos-endpoint");

        Environment.SetEnvironmentVariable(
            "COSMOS_ENDPOINT",
            cosmosEndpointFromKv);

        // Application Insights
        var appInsightsConnString =
            await kvLoader.GetRequiredSecretAsync("appinsights-connection-string");

        builder.Services.AddApplicationInsightsTelemetry(options =>
        {
            options.ConnectionString = appInsightsConnString;
        });
    }

    // ---------------------------------------------------------------
    // Load configuration
    // ---------------------------------------------------------------
    builder.Configuration
        .SetBasePath(Directory.GetCurrentDirectory())
        .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
        .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true)
        .AddEnvironmentVariables();

    var config = builder.Configuration;

    // ---------------------------------------------------------------
    // Cosmos DB registration
    // ---------------------------------------------------------------
    builder.Services.AddSingleton<CosmosClient>(sp =>
    {
        var configuration = sp.GetRequiredService<IConfiguration>();

        var endpoint = configuration["COSMOS_ENDPOINT"]
            ?? throw new InvalidOperationException("COSMOS_ENDPOINT missing");

        var authMode = configuration["AuthMode"] ?? "Key";

        if (authMode.Equals("ManagedIdentity", StringComparison.OrdinalIgnoreCase))
        {
            return new CosmosClient(endpoint, new DefaultAzureCredential());
        }

        var key = Environment.GetEnvironmentVariable("COSMOS_KEY")
            ?? throw new InvalidOperationException("COSMOS_KEY missing");

        return new CosmosClient(endpoint, key);
    });

    builder.Services.AddScoped<IAccountRepository>(provider =>
    {
        var client = provider.GetRequiredService<CosmosClient>();
        var configuration = provider.GetRequiredService<IConfiguration>();

        return new CosmosAccountRepository(client, configuration);
    });

    // ---------------------------------------------------------------
    // Swagger
    // ---------------------------------------------------------------
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    var app = builder.Build();

    app.UseSwagger();
    app.UseSwaggerUI();

    app.UseHttpsRedirection();

    // ---------------------------------------------------------------
    // CRUD API
    // ---------------------------------------------------------------
    app.MapPost("/api/accounts", async (CreateAccountDto dto, IAccountRepository repo) =>
    {
        var account = new Account
        {
            Id = Guid.NewGuid().ToString(),
            CustomerName = dto.CustomerName,
            Email = dto.Email,
            Balance = dto.Balance
        };

        var created = await repo.CreateAsync(account);

        return Results.Created($"/api/accounts/{created.Id}", new AccountDto(
            created.Id,
            created.CustomerName,
            created.Email,
            created.Balance,
            created.CreatedAt
        ));
    });

    app.MapGet("/api/accounts/{id}", async (string id, IAccountRepository repo) =>
    {
        var account = await repo.GetByIdAsync(id);
        return account is null
            ? Results.NotFound()
            : Results.Ok(new AccountDto(
                account.Id,
                account.CustomerName,
                account.Email,
                account.Balance,
                account.CreatedAt
            ));
    });

    app.MapGet("/api/accounts", async (IAccountRepository repo) =>
    {
        var accounts = await repo.GetAllAsync();
        return Results.Ok(accounts.Select(a =>
            new AccountDto(a.Id, a.CustomerName, a.Email, a.Balance, a.CreatedAt)));
    });

    app.MapPut("/api/accounts/{id}", async (string id, CreateAccountDto dto, IAccountRepository repo) =>
    {
        var existing = await repo.GetByIdAsync(id);
        if (existing is null) return Results.NotFound();

        existing.CustomerName = dto.CustomerName;
        existing.Email = dto.Email;
        existing.Balance = dto.Balance;

        var result = await repo.UpdateAsync(id, existing);
        return Results.Ok(new AccountDto(
            result.Id,
            result.CustomerName,
            result.Email,
            result.Balance,
            result.CreatedAt
        ));
    });

    app.MapDelete("/api/accounts/{id}", async (string id, IAccountRepository repo) =>
    {
        var deleted = await repo.DeleteAsync(id);
        return deleted ? Results.NoContent() : Results.NotFound();
    });

    app.Run();
