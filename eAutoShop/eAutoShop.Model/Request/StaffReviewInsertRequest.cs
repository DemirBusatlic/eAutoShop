using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;
using System.Text.Json.Serialization;

namespace eAutoShop.Model.Request
{
    public class StaffReviewInsertRequest
    {
        [Required(ErrorMessage = "Ocjena je obavezna.")]
        [Range(1, 5, ErrorMessage = "Ocjena mora biti između 1 i 5.")]
        public int Rating { get; set; }

        [MaxLength(1000, ErrorMessage = "Komentar ne može imati više od 1000 znakova.")]
        public string? Comment { get; set; }

        [JsonIgnore]
        public int? UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Rezervacija nije ispravna.")]
        public int AppointmentId { get; set; }
    }
}
