using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace eAutoShop.Api.SignalR
{
    [Authorize]
    public class NotificationHub : Hub
    {
    }
}
