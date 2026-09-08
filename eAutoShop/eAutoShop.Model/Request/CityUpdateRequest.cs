using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class CityUpdateRequest
    {
        [Required(ErrorMessage = "Naziv grada je obavezan.")]
        [MaxLength(50, ErrorMessage = "Naziv grada može imati najviše 50 znakova.")]
        public string Name { get; set; } = null!;
    }
}
