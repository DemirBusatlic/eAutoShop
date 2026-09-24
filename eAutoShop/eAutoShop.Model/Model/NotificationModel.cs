using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class NotificationModel
    {
        public int Id { get; set; }

        public string Title { get; set; } = null!;

        public string Message { get; set; } = null!;

        public string Type { get; set; } = null!;

        public DateTime CreatedAt { get; set; }

        public bool IsRead { get; set; }
    }
}
