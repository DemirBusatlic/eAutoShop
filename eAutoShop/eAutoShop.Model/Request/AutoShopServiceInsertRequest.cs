using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AutoShopServiceInsertRequest
    {
        public int ServiceTypeId { get; set; }

        public string Name { get; set; } = null!;

        public double Price { get; set; }

        public double? Discount { get; set; }

        public string? ImageData { get; set; }

        public string Description { get; set; } = null!;

        public string? Details { get; set; }

        public string Duration { get; set; } = null!;
    }
}
