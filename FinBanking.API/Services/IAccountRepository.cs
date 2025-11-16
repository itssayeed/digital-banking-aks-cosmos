namespace FinBanking.Api.Services;

public interface IAccountRepository
{
    Task<Account> CreateAsync(Account account);
    Task<Account?> GetByIdAsync(string id);
    Task<IEnumerable<Account>> GetAllAsync();
    Task<Account?> UpdateAsync(string id, Account account);
    Task<bool> DeleteAsync(string id);
}
