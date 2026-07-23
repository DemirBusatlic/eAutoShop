using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class AutoShopService
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public double Price { get; set; }

    public double Discount { get; set; }

    public double DiscountedPrice { get; set; }

    public byte[] Image { get; set; } = null!;

    public string Description { get; set; } = null!;

    public int ServiceTypeId { get; set; }

    public string State { get; set; } = null!;

    public string? Details { get; set; }

    public TimeOnly Duration { get; set; }

    public virtual ICollection<AppointmentDetail> AppointmentDetails { get; set; } = new List<AppointmentDetail>();

    public virtual ServiceType ServiceType { get; set; } = null!;
}
