using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel.DataAnnotations;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class UserUpdateRequest
    {
        public int UserId { get; set; }
        [MaxLength(100)]
        public string? Username { get; set; }

        [MaxLength(100)]
        public string? Name { get; set; }
        [MaxLength(100)]
        public string? Surname { get; set; }
        public string? Image { get; set; }

        [EmailAddress, MaxLength(100)]
        public string? Email { get; set; }
        [Phone, MaxLength(50)]
        public string? Phone { get; set; }

        [MaxLength(10)]
        public string? Gender { get; set; }
        [MaxLength(255)]
        public string? Address { get; set; }

        [MaxLength(20)]
        public string? PostalCode { get; set; }
        [Range(1, int.MaxValue)]
        public int? CityId { get; set; }
        [Range(1, int.MaxValue)]
        public int? RoleId { get; set; }

    }
}