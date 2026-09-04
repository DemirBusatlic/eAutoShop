using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class AutoShopServiceModel
    {
        public int Id { get; set; }

        public string Name { get; set; } = null!;

        public int ServiceTypeId { get; set; }

        public string ServiceTypeName { get; set; } = null!;

        public double Price { get; set; }

        public double Discount { get; set; }

        public double DiscountedPrice { get; set; }

        public string State { get; set; } = null!;

        public string? ImageData { get; set; }

        public string Description { get; set; } = null!;

        public string? Details { get; set; }

        public TimeSpan Duration { get; set; }
    }

}
