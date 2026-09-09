using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{

    public class UserChangePasswordRequest
    {
        [Required(ErrorMessage = "Stara lozinka je obavezna.")]
        public string OldPassword { get; set; } = null!;

        [Required(ErrorMessage = "Nova lozinka je obavezna.")]
        [MinLength(
            6,
            ErrorMessage = "Nova lozinka mora imati najmanje 6 znakova.")]
        public string NewPassword { get; set; } = null!;

        [Required(ErrorMessage = "Potvrda nove lozinke je obavezna.")]
        [Compare(
            nameof(NewPassword),
            ErrorMessage = "Lozinke se ne podudaraju.")]
        public string ConfirmNewPassword { get; set; } = null!;
    }

}
