using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class CarManufacturer
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<CarModel> CarModels { get; set; } = new List<CarModel>();
}
