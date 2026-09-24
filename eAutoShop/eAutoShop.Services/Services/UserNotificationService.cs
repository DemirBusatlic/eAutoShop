using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Services
{
    public class UserNotificationService : INotificationService
    {
        private readonly AutoShopContext _context;
        private readonly IMapper _mapper;

        public UserNotificationService(AutoShopContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<List<NotificationModel>> GetByUser(int userId)
        {
            var notifications = await _context.Notifications
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<NotificationModel>>(notifications);
        }

        public async Task<NotificationModel> MarkAsRead(int id, int userId)
        {
            var notification = await _context.Notifications.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (notification == null)
            {
                throw new UserException("Notifikacija nije pronađena.");
            }

            if (!notification.IsRead)
            {
                notification.IsRead = true;
                await _context.SaveChangesAsync();
            }

            return _mapper.Map<NotificationModel>(notification);
        }
    }
}
