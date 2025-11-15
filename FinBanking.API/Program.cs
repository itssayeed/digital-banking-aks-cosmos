using FinBanking.Api.Models;
using FinBanking.Api.Services;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder(args);

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Cosmos client registration
var cosmosConn = builder.Configuration["COSMOS_CONN_STRING"];
builder.Services.AddSingleton(s => new CosmosClient(cosmosConn));

// Register repository to use Cosmos instead of in-memory
builder.Services.AddSingleton<IAccountRepository, CosmosAccountRepository>();

var app = builder.Build();

// Middleware
app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/", () => "FinBanking API is running with Cosmos DB 🌩️");

// POST: Create
app.MapPost("/api/accounts", async (Account account, IAccountRepository repo) =>
{
    if (string.IsNullOrWhiteSpace(account.CustomerName) || string.IsNullOrWhiteSpace(account.Email))
        return Results.BadRequest("CustomerName and Email are required.");

    var created = await repo.CreateAsync(account);
    return Results.Created($"/api/accounts/{created.Id}", created);
});

// GET: List all
app.MapGet("/api/accounts", async (IAccountRepository repo) =>
{
    return Results.Ok(await repo.GetAllAsync());
});

// GET: By ID
app.MapGet("/api/accounts/{id}", async (string id, IAccountRepository repo) =>
{
    var account = await repo.GetByIdAsync(id);
    return account is null ? Results.NotFound() : Results.Ok(account);
});

// PUT: Update
app.MapPut("/api/accounts/{id}", async (string id, Account updated, IAccountRepository repo) =>
{
    var result = await repo.UpdateAsync(id, updated);
    return result is null ? Results.NotFound() : Results.Ok(result);
});

// DELETE: Delete
app.MapDelete("/api/accounts/{id}", async (string id, IAccountRepository repo) =>
{
    var deleted = await repo.DeleteAsync(id);
    return deleted ? Results.NoContent() : Results.NotFound();
});

app.Run();
