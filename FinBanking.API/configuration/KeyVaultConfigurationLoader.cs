using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace FinBanking.Api.Configuration;

public class KeyVaultConfigurationLoader
{
    private readonly SecretClient _secretClient;

    public KeyVaultConfigurationLoader(string keyVaultUri)
    {
        if (string.IsNullOrWhiteSpace(keyVaultUri))
            throw new InvalidOperationException("Key Vault URI is missing");

        _secretClient = new SecretClient(
            new Uri(keyVaultUri),
            new DefaultAzureCredential());
    }

    public async Task<string> GetRequiredSecretAsync(string secretName)
    {
        if (string.IsNullOrWhiteSpace(secretName))
            throw new ArgumentException("Secret name cannot be empty");

        KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);

        if (string.IsNullOrWhiteSpace(secret.Value))
            throw new InvalidOperationException($"Secret '{secretName}' is empty or missing");

        return secret.Value;
    }
}
