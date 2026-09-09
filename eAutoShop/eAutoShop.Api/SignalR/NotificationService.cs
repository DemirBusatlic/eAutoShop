using eAutoShop.Services.Database;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Api.SignalR
{
    public class NotificationService
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly AutoShopContext _context;

        public NotificationService(IHubContext<NotificationHub> hubContext, AutoShopContext context)
        {
            _hubContext = hubContext;
            _context = context;
        }

        public async Task SendServiceNotification(string message, string type)
        {
            await _hubContext.Clients.All.SendAsync("newNotification",
                new
                {
                    Message = message,
                    Type = type
                });
        }

        public async Task SendUserNotification(int userId, string message, string type)
        {
            var username = await _context.Users
                .Where(x => x.Id == userId)
                .Select(x => x.Username)
                .FirstOrDefaultAsync();

            if (string.IsNullOrWhiteSpace(username))
            {
                throw new InvalidOperationException($"Korisnik sa ID-em {userId} nije pronađen.");
            }

            await _hubContext.Clients.User(username).SendAsync("newNotification",
                    new
                    {
                        Message = message,
                        Type = type
                    });
        }
    }
}