// Program.cs
using FinBanking.Api.DTOs;
using FinBanking.Api.Services;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder(args);

// Register Cosmos Client & Repository
var cosmosConn = builder.Configuration["COSMOS_CONN_STRING"]
    ?? throw new InvalidOperationException("COSMOS_CONN_STRING missing");

builder.Services.AddSingleton<CosmosClient>(new CosmosClient(cosmosConn));
builder.Services.AddScoped<IAccountRepository, CosmosAccountRepository>();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// === CRUD ENDPOINTS ===

// CREATE
app.MapPost("/api/accounts", async (CreateAccountDto dto, IAccountRepository repo) =>
{
    var account = new Account
    {
        Id=Guid.NewGuid().ToString(),
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
        Id = id, // Keep same id
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