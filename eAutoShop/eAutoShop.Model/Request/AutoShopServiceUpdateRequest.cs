using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class AutoShopServiceUpdateRequest
    {
        public int? ServiceTypeId { get; set; }

        public string? Name { get; set; }

        public double? Price { get; set; }

        public double? Discount { get; set; }

        public string? ImageData { get; set; }

        public string? Description { get; set; }

        public string? Details { get; set; }

        public string? Duration { get; set; }
    }
}
