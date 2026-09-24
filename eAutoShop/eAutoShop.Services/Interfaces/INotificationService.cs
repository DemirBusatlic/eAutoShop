using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using eAutoShop.Model.Model;

namespace eAutoShop.Services.Interfaces
{
    public interface INotificationService
    {
        Task<List<NotificationModel>> GetByUser(int userId);

        Task<NotificationModel> MarkAsRead(int id, int userId);
    }
}
