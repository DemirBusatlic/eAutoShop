using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class CarModel
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string ModelYear { get; set; } = null!;

    public int CarManufacturerId { get; set; }

    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

    public virtual CarManufacturer CarManufacturer { get; set; } = null!;

    public virtual ICollection<Product> Products { get; set; } = new List<Product>();
}
