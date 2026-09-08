using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class ProductCategoryInsertRequest
    {
        [Required(ErrorMessage = "Naziv kategorije je obavezan.")]
        [MaxLength(50, ErrorMessage = "Naziv kategorije može imati najviše 50 znakova.")]
        public string Name { get; set; } = null!;
    }
}
