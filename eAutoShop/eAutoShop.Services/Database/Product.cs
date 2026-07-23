using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class Product
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public double Price { get; set; }

    public double Discount { get; set; }

    public double DiscountedPrice { get; set; }

    public string State { get; set; } = null!;

    public int? ProductCategoryId { get; set; }

    public byte[]? Image { get; set; }

    public string? Description { get; set; }

    public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

    public virtual ProductCategory? ProductCategory { get; set; }

    public virtual ICollection<ProductReview> ProductReviews { get; set; } = new List<ProductReview>();

    public virtual ICollection<CarModel> CarModels { get; set; } = new List<CarModel>();
}
