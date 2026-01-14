using FinBanking.Api.DTOs;
using FinBanking.Api.Services;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder(args);

// ---------------------------------------------------------------
// Load configuration (supports local via appsettings.Development.json,
// Docker via env variables, and AKS via secrets)
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
var cosmosConn = config["COSMOS_ENDPOINT"]
    ?? throw new InvalidOperationException("COSMOS_ENDPOINT missing");

builder.Services.AddSingleton<CosmosClient>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();

    var endpoint = configuration["COSMOS_ENDPOINT"]
        ?? throw new InvalidOperationException("COSMOS_ENDPOINT missing");

    var authMode = configuration["AuthMode"] ?? "Key";

    // 🔐 Managed Identity (FOR LATER)
    if (authMode.Equals("ManagedIdentity", StringComparison.OrdinalIgnoreCase))
    {
        throw new NotSupportedException(
            "ManagedIdentity is not enabled yet. Switch AuthMode to 'Key'."
        );

        // Later you will replace above with:
        // return new CosmosClient(endpoint, new DefaultAzureCredential());
    }

    // 🔑 Key-based auth (CURRENT)
    var key = Environment.GetEnvironmentVariable("COSMOS_KEY")
        ?? throw new InvalidOperationException("COSMOS_KEY missing");

    return new CosmosClient(endpoint, key);
});


// MATCHES your exact repository constructor: (CosmosClient, IConfiguration)
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
// CRUD API ENDPOINTS
// ---------------------------------------------------------------

// CREATE
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

// READ ONE
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

// READ ALL
app.MapGet("/api/accounts", async (IAccountRepository repo) =>
{
    var accounts = await repo.GetAllAsync();
    var dtos = accounts.Select(a => new AccountDto(
        a.Id, a.CustomerName, a.Email, a.Balance, a.CreatedAt
    ));
    return Results.Ok(dtos);
});

// UPDATE
app.MapPut("/api/accounts/{id}", async (string id, CreateAccountDto dto, IAccountRepository repo) =>
{
    var existing = await repo.GetByIdAsync(id);
    if (existing is null) return Results.NotFound();

    var updated = new Account
    {
        Id = id,
        CustomerName = dto.CustomerName,
        Email = dto.Email,
        Balance = dto.Balance
    };

    var result = await repo.UpdateAsync(id, updated);
    return result is null
        ? Results.BadRequest()
        : Results.Ok(new AccountDto(
            result.Id,
            result.CustomerName,
            result.Email,
            result.Balance,
            result.CreatedAt
        ));
});

// DELETE
app.MapDelete("/api/accounts/{id}", async (string id, IAccountRepository repo) =>
{
    var deleted = await repo.DeleteAsync(id);
    return deleted ? Results.NoContent() : Results.NotFound();
});

app.Run();
