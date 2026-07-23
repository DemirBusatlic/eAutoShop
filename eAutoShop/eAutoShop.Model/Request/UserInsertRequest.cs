using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class UserInsertRequest
    {
        public string? Name { get; set; }
        public string? Surname { get; set; }

        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;

        public string? Phone { get; set; }
        public string? Gender { get; set; }
        public string? Image { get; set; }

        public string Password { get; set; } = null!;
        public string PasswordConfirm { get; set; } = null!;

        public int CityId { get; set; }
        public int? RoleId { get; set; }
        public string? Address { get; set; }
        public string? PostalCode { get; set; }


    }
}

