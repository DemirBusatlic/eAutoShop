using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class PasswordResetEmailModel
    {
        public string Email { get; set; } = null!;

        public string RecipientName { get; set; } = null!;

        public string Code { get; set; } = null!;

        public DateTime ExpiresAt { get; set; }
    }
}
