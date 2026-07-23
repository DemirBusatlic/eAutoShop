using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AppointmentUpdateRequest
    {
        public DateTime? ReservationDate { get; set; }

        public DateTime? EstimatedCompletionDate { get; set; }

        public DateTime? CompletionDate { get; set; }
    }
}
