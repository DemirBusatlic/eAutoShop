using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AppointmentInsertRequest
    {
        [Range(1, int.MaxValue)]
        public int CarModelId { get; set; }

        public DateTime ReservationDate { get; set; }

        [Required, MinLength(1)]
        public List<int> Services { get; set; } = new List<int>();
    }
}

