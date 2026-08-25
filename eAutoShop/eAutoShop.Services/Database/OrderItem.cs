using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class OrderItem
{
    public int Id { get; set; }

    public int OrderId { get; set; }

    public int ProductId { get; set; }

    public int Quantity { get; set; }

    public double UnitPrice { get; set; }

    public double TotalItemPrice { get; set; }

    public double TotalItemPriceDiscounted { get; set; }

    public double Discount { get; set; }

    public virtual Order Order { get; set; } = null!;

    public virtual Product Product { get; set; } = null!;

    public virtual ProductReview? ProductReview { get; set; }
}
