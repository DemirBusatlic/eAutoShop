using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class ServiceTypeUpdateRequest
    {
        [Required(ErrorMessage = "Naziv tipa usluge je obavezan.")]
        [MaxLength(50)]
        public string Name { get; set; } = null!;

        public string? Image { get; set; }
    }
}
