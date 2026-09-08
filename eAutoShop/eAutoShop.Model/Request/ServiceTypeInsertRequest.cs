using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class ServiceTypeInsertRequest
    {
        [Required(ErrorMessage = "Naziv tipa usluge je obavezan.")]
        [MaxLength(50)]
        public string Name { get; set; } = null!;

        [Required(ErrorMessage = "Slika je obavezna.")]
        public string Image { get; set; } = null!;
    }
}
