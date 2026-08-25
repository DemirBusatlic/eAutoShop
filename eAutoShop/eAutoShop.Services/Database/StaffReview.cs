using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class StaffReview
{
    public int Id { get; set; }

    public int? UserId { get; set; }

    public int? EmployeeId { get; set; }

    public int? AppointmentId { get; set; }

    public int? Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Appointment? Appointment { get; set; }

    public virtual User? Employee { get; set; }

    public virtual User? User { get; set; }
}
