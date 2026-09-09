using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AppointmentConfirmRequest
    {
        [Range(1, int.MaxValue)]
        public int EmployeeId { get; set; }

        public DateTime? EstimatedCompletionDate { get; set; }
    }
}
