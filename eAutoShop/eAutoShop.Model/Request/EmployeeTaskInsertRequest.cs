using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace eAutoShop.Model.Request
{
    public class EmployeeTaskInsertRequest
    {
        [Required(ErrorMessage = "Naslov je obavezan.")]
        [MaxLength(150, ErrorMessage = "Naslov ne može imati više od 150 znakova.")]
        public string Title { get; set; } = null!;

        [Required(ErrorMessage = "Opis je obavezan.")]
        [MaxLength(1000, ErrorMessage = "Opis ne može imati više od 1000 znakova.")]
        public string Description { get; set; } = null!;

        [Range(1, int.MaxValue, ErrorMessage = "Radnik nije ispravan.")]
        public int EmployeeId { get; set; }

        public DateTime? DueDate { get; set; }
    }
}
