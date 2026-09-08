using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class CarManufacturerInsertRequest
    {
        [Required(ErrorMessage = "Naziv proizvođača je obavezan.")]
        [MaxLength(50, ErrorMessage = "Naziv može imati najviše 50 znakova.")]
        public string Name { get; set; } = null!;
    }
}
