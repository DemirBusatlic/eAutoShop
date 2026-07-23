using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AppointmentInsertRequest
    {
        public int CarModelId { get; set; }

        public int? OrderId { get; set; }

        public DateTime ReservationDate { get; set; }

        public List<int> Services { get; set; } = new List<int>();
    }
}
