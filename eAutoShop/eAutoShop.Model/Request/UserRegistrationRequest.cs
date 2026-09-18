using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace eAutoShop.Model.Request
{
    public class UserRegistrationRequest
    {
        [Required, MaxLength(100)]
        public string? Name { get; set; }

        [Required, MaxLength(100)]
        public string? Surname { get; set; }

        [Required, MaxLength(100)]
        public string Username { get; set; } = null!;

        [Required, EmailAddress, MaxLength(100)]
        public string Email { get; set; } = null!;

        [Phone, MaxLength(50)]
        public string? Phone { get; set; }

        [MaxLength(10)]
        public string? Gender { get; set; }

        public string? Image { get; set; }

        [Required, MinLength(6)]
        public string Password { get; set; } = null!;

        [Required]
        [Compare(nameof(Password),ErrorMessage = "Lozinke se ne podudaraju.")]
        public string PasswordConfirm { get; set; } = null!;

        [Range(1, int.MaxValue)]
        public int CityId { get; set; }

        [MaxLength(255)]
        public string? Address { get; set; }

        [MaxLength(20)]
        public string? PostalCode { get; set; }
    }
}