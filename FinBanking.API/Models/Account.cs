using Newtonsoft.Json;
using System.Text.Json.Serialization;

public class Account
{
    [JsonProperty("id")]  // Cosmos DB requires this
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    public string CustomerName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public decimal Balance { get; set; } = 0m;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
