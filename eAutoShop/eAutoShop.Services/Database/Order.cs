using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class Order
{
    public int Id { get; set; }

    public int? CustomerId { get; set; }

    public int EmployeeId { get; set; }

    public DateTime OrderDate { get; set; }

    public DateTime ShippingDate { get; set; }

    public double TotalAmount { get; set; }

    public string ShippingAddress { get; set; } = null!;

    public string PostalCode { get; set; } = null!;

    public int CityId { get; set; }

    public string? PaymentIntentId { get; set; }

    public string State { get; set; } = null!;

    public bool DeletedByShop { get; set; }

    public bool DeletedByCustomer { get; set; }

    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

    public virtual City City { get; set; } = null!;

    public virtual User? Customer { get; set; }

    public virtual User Employee { get; set; } = null!;

    public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
}
