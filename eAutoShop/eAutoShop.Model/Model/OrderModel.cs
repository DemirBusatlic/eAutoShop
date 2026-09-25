using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class OrderModel
    {
        public int Id { get; set; }

        public int? CustomerId { get; set; }

        public int EmployeeId { get; set; }

        public string Username { get; set; } = null!;

        public DateTime OrderDate { get; set; }

        public DateTime? ShippingDate { get; set; }

        public double TotalAmount { get; set; }

        public string State { get; set; } = null!;

        public string? AcceptedBy { get; set; }

        public DateTime? AcceptedAt { get; set; }

        public string? RejectedBy { get; set; }

        public DateTime? RejectedAt { get; set; }

        public string? RejectionReason { get; set; }

        public string? CancelledBy { get; set; }

        public DateTime? CancelledAt { get; set; }

        public string? CancellationReason { get; set; }

        public string? CompletedBy { get; set; }

        public DateTime? CompletedAt { get; set; }

        public int CityId { get; set; }

        public string ShippingCity { get; set; } = null!;

        public string ShippingAddress { get; set; } = null!;

        public string ShippingPostalCode { get; set; } = null!;
    }
}
