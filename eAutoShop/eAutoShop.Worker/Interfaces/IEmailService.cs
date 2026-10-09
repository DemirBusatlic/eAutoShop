using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using eAutoShop.Model.Model;

namespace eAutoShop.Worker.Interfaces
{
    public interface IEmailService
    {
        Task SendPasswordResetEmail(PasswordResetEmailModel notification);
    }
}
