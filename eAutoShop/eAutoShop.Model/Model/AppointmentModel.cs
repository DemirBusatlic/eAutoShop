using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class AppointmentModel
    {
        public int Id { get; set; }

        public int CustomerId { get; set; }
        public string CustomerUsername { get; set; } = null!;

        public int? EmployeeId { get; set; }
        public string? EmployeeUsername { get; set; }

        public int? OrderId { get; set; }

        public string CarModel { get; set; } = null!;
        public string? RejectionReason { get; set; }

        public string? CancellationReason { get; set; }

        public DateTime ReservationCreatedDate { get; set; }
        public DateTime ReservationDate { get; set; }

        public DateTime? EstimatedCompletionDate { get; set; }
        public DateTime? CompletionDate { get; set; }

        public double TotalAmount { get; set; }
        public TimeSpan TotalDuration { get; set; }

        public string State { get; set; } = null!;
        public string Type { get; set; } = null!;
    }
}
