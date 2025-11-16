namespace FinBanking.Api.DTOs
{
    public record CreateAccountDto(
        string CustomerName,
        string Email,
        decimal Balance);

    public record AccountDto(
        string Id,
        string CustomerName,
        string Email,
        decimal Balance,
        DateTime CreatedAt);
}
