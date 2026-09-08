using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class CarModelInsertRequest
    {
        [Required(ErrorMessage = "Naziv modela je obavezan.")]
        [MaxLength(100)]
        public string Name { get; set; } = null!;

        [Required(ErrorMessage = "Godište modela je obavezno.")]
        [MaxLength(10)]
        public string ModelYear { get; set; } = null!;

        [Range(1, int.MaxValue, ErrorMessage = "Proizvođač je obavezan.")]
        public int CarManufacturerId { get; set; }
    }
}
