using FinBanking.Api.Models;
using Microsoft.Azure.Cosmos;

namespace FinBanking.Api.Services;

public class CosmosAccountRepository : IAccountRepository
{
    private readonly Container _container;

    public CosmosAccountRepository(CosmosClient client, IConfiguration config)
    {
        var databaseName = config["COSMOS_DATABASE"];
        var containerName = config["COSMOS_CONTAINER"];
        _container = client.GetContainer(databaseName, containerName);
    }

    public async Task<Account> CreateAsync(Account account)
    {
        await _container.CreateItemAsync(account, new PartitionKey(account.Id));
        return account;
    }

    public async Task<Account?> GetByIdAsync(string id)
    {
        try
        {
            var response = await _container.ReadItemAsync<Account>(id, new PartitionKey(id));
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<IEnumerable<Account>> GetAllAsync()
    {
        var query = _container.GetItemQueryIterator<Account>("SELECT * FROM c");
        List<Account> results = new();
        while (query.HasMoreResults)
            results.AddRange(await query.ReadNextAsync());
        return results;
    }

    public async Task<Account?> UpdateAsync(string id, Account account)
    {
        try
        {
            account.Id = id;
            var response = await _container.ReplaceItemAsync(account, id, new PartitionKey(id));
            return response.Resource;
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> DeleteAsync(string id)
    {
        try
        {
            await _container.DeleteItemAsync<Account>(id, new PartitionKey(id));
            return true;
        }
        catch
        {
            return false;
        }
    }
}
