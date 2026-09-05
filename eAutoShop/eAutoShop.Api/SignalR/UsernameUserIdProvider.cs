using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace eAutoShop.Api.SignalR
{
    public class UsernameUserIdProvider : IUserIdProvider
    {
        public string? GetUserId(HubConnectionContext connection)
        {
            return connection.User?.FindFirst(ClaimTypes.Name)?.Value;
        }
    }
}
