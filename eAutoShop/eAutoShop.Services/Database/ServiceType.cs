using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class ServiceType
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public byte[] Image { get; set; } = null!;

    public virtual ICollection<AutoShopService> AutoShopServices { get; set; } = new List<AutoShopService>();
}
