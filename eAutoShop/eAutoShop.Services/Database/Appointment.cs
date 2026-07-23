using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class Appointment
{
    public int Id { get; set; }

    public int? EmployeeId { get; set; }

    public int CustomerId { get; set; }

    public int? OrderId { get; set; }

    public DateTime ReservationCreatedDate { get; set; }

    public DateTime ReservationDate { get; set; }

    public DateTime? EstimatedCompletionDate { get; set; }

    public DateTime? CompletionDate { get; set; }

    public double TotalAmount { get; set; }

    public int CarModelId { get; set; }

    public TimeOnly TotalDuration { get; set; }

    public string State { get; set; } = null!;

    public string Type { get; set; } = null!;

    public string? PaymentIntentId { get; set; }

    public bool DeletedByShop { get; set; }

    public bool DeletedByCustomer { get; set; }

    public string? RejectionReason { get; set; }

    public string? CancellationReason { get; set; }

    public virtual ICollection<AppointmentDetail> AppointmentDetails { get; set; } = new List<AppointmentDetail>();

    public virtual CarModel CarModel { get; set; } = null!;

    public virtual User Customer { get; set; } = null!;

    public virtual User? Employee { get; set; }

    public virtual Order? Order { get; set; }
}
