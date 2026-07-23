using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class AppointmentSearchObject : BaseSearchObject
    {
        public string? CustomerUsername { get; set; }

        public string? EmployeeUsername { get; set; }

        public string? State { get; set; }

        public string? Type { get; set; }

        public double? MinTotalAmount { get; set; }

        public double? MaxTotalAmount { get; set; }

        public bool? HasOrder { get; set; }

        public DateTime? MinCreatedDate { get; set; }

        public DateTime? MaxCreatedDate { get; set; }

        public DateTime? MinReservationDate { get; set; }

        public DateTime? MaxReservationDate { get; set; }

        public DateTime? MinCompletionDate { get; set; }

        public DateTime? MaxCompletionDate { get; set; }
    }
}
