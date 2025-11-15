using System;
using System.Text.Json.Serialization;

namespace FinBanking.Api.Models
{
    public class Account
    {
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        public string Id { get; set; } = Guid.NewGuid().ToString();

        public string CustomerName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public decimal Balance { get; set; } = 0m;

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
