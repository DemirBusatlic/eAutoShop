using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class UserResetPasswordRequest
    {
        public string Email { get; set; } = null!;

        public string Code { get; set; } = null!;

        public string NewPassword { get; set; } = null!;

        public string ConfirmNewPassword { get; set; } = null!;
    }
}
