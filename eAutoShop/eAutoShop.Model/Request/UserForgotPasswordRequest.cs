using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class UserForgotPasswordRequest
    {
        public string Email { get; set; } = null!;
    }
}
