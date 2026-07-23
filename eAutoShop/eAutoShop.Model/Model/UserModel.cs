using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class UserModel
    {
        public int Id { get; set; }

        public string? Name { get; set; }
        public string? Surname { get; set; }

        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Username { get; set; }

        public DateTime CreatedAt { get; set; }
        public string? Gender { get; set; }
        public string? Image { get; set; }
        public bool Active { get; set; }
        public string? Address { get; set; }
        public string? PostalCode { get; set; }

        public int? CityId { get; set; }
        public string? CityName { get; set; }

        public int? RoleId { get; set; }
        public string? RoleName { get; set; }
    }
}
