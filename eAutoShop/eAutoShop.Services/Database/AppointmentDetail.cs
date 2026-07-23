using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class AppointmentDetail
{
    public int Id { get; set; }

    public int AppointmentId { get; set; }

    public int ServiceId { get; set; }

    public string ServiceName { get; set; } = null!;

    public double ServicePrice { get; set; }

    public double ServiceDiscount { get; set; }

    public double ServiceDiscountedPrice { get; set; }

    public virtual Appointment Appointment { get; set; } = null!;

    public virtual AutoShopService Service { get; set; } = null!;
}
