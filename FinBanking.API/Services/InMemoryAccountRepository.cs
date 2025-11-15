using FinBanking.Api.Models;
using System.Collections.Concurrent;

namespace FinBanking.Api.Services;

public class InMemoryAccountRepository : IAccountRepository
{
    private readonly ConcurrentDictionary<string, Account> _store = new();

    public Task<Account> CreateAsync(Account account)
    {
        _store.TryAdd(account.Id, account);
        return Task.FromResult(account);
    }

    public Task<Account?> GetByIdAsync(string id)
    {
        _store.TryGetValue(id, out var result);
        return Task.FromResult(result);
    }

    public Task<IEnumerable<Account>> GetAllAsync()
    {
        return Task.FromResult(_store.Values.AsEnumerable());
    }

    public Task<Account?> UpdateAsync(string id, Account account)
    {
        if (!_store.ContainsKey(id))
            return Task.FromResult<Account?>(null);

        account.Id = id;
        _store[id] = account;
        return Task.FromResult<Account?>(account);
    }

    public Task<bool> DeleteAsync(string id)
    {
        return Task.FromResult(_store.TryRemove(id, out _));
    }
}
