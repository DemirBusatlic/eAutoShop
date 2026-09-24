using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database
{
    public partial class Notification
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public string Title { get; set; } = null!;

        public string Message { get; set; } = null!;

        public string Type { get; set; } = null!;

        public DateTime CreatedAt { get; set; }

        public bool IsRead { get; set; }

        public virtual User User { get; set; } = null!;
    }
}
