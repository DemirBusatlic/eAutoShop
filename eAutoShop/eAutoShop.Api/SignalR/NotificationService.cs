using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using NotificationEntity = eAutoShop.Services.Database.Notification;

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
            var customers = await _context.Users.AsNoTracking().Where(x =>x.Active && x.Role.Name == UserRoles.Customer).Select(x => new{x.Id, x.Username}).ToListAsync();

            if (customers.Count == 0)
            {
                return;
            }

            var title = GetTitle(type);
            var createdAt = DateTime.UtcNow;

            var notifications = customers.Select(customer => new NotificationEntity
                {
                    UserId = customer.Id,
                    Title = title,
                    Message = message,
                    Type = type,
                    CreatedAt = createdAt,
                    IsRead = false
                }).ToList();

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.Users(customers.Select(x => x.Username)).SendAsync("newNotification",new{Title = title,Message = message,Type = type,CreatedAt = createdAt });
        }

        public async Task SendUserNotification(
            int userId,
            string message,
            string type
        )
        {
            var user = await _context.Users
                .AsNoTracking()
                .Where(x => x.Id == userId)
                .Select(x => new
                {
                    x.Id,
                    x.Username
                })
                .FirstOrDefaultAsync();

            if (user == null || string.IsNullOrWhiteSpace(user.Username))
            {
                throw new InvalidOperationException($"Korisnik sa ID-em {userId} nije pronađen.");
            }

            var title = GetTitle(type);
            var createdAt = DateTime.UtcNow;

            var notification = new NotificationEntity
            {
                UserId = user.Id,
                Title = title,
                Message = message,
                Type = type,
                CreatedAt = createdAt,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            await _hubContext.Clients.User(user.Username).SendAsync("newNotification", new
                   {
                        Title = title,
                        Message = message,
                        Type = type,
                        CreatedAt = createdAt
                    }
                );
        }

        private static string GetTitle(string type)
        {
            return type switch
            {
                "reservationstatuschanged" => "Status rezervacije",
                "orderstatuschanged" => "Status narudžbe",
                "product_activated" => "Novi proizvod",
                _ => "Obavijest"
            };
        }
    }
}