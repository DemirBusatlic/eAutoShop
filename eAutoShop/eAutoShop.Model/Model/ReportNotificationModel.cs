using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class ReportNotificationModel
    {
        public string Username { get; set; } = null!;
        public string NotificationType { get; set; } = null!;
        public string Message { get; set; } = null!;
    }
}
