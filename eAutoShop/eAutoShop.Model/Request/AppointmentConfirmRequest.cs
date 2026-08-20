using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AppointmentConfirmRequest
    {
        public int EmployeeId { get; set; }

        public DateTime? EstimatedCompletionDate { get; set; }
    }
}
