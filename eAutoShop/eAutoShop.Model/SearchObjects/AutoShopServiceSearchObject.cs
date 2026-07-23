using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class AutoShopServiceSearchObject : BaseSearchObject
    {
        public int? ServiceTypeId { get; set; }
        public string? ServiceType { get; set; }

        public string? Name { get; set; }

        public bool? WithDiscount { get; set; }

        public string? State { get; set; }
    }
}
