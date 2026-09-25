using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class Appointment
{
    public int Id { get; set; }

    public int? EmployeeId { get; set; }

    public int CustomerId { get; set; }

    public DateTime ReservationCreatedDate { get; set; }

    public DateTime ReservationDate { get; set; }

    public DateTime? EstimatedCompletionDate { get; set; }

    public DateTime? CompletionDate { get; set; }

    public double TotalAmount { get; set; }

    public int CarModelId { get; set; }

    public TimeOnly TotalDuration { get; set; }

    public string State { get; set; } = null!;

    public string Type { get; set; } = null!;

    public bool DeletedByShop { get; set; }

    public bool DeletedByCustomer { get; set; }

    public string? RejectionReason { get; set; }

    public string? CancellationReason { get; set; }

    public string? ConfirmedBy { get; set; }

    public DateTime? ConfirmedAt { get; set; }

    public string? RejectedBy { get; set; }

    public DateTime? RejectedAt { get; set; }

    public string? CancelledBy { get; set; }

    public DateTime? CancelledAt { get; set; }

    public string? StartedBy { get; set; }

    public DateTime? StartedAt { get; set; }

    public string? CompletedBy { get; set; }

    public virtual ICollection<AppointmentDetail> AppointmentDetails { get; set; } = new List<AppointmentDetail>();

    public virtual CarModel CarModel { get; set; } = null!;

    public virtual User Customer { get; set; } = null!;

    public virtual User? Employee { get; set; }

    public virtual StaffReview? StaffReview { get; set; }
}
