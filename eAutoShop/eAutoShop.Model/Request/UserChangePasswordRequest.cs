using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
   
        public class UserChangePasswordRequest
        {
            public string Token { get; set; } = null!;

            public string OldPassword { get; set; } = null!;

            public string NewPassword { get; set; } = null!;

            public string ConfirmNewPassword { get; set; } = null!;
        }
    
}
