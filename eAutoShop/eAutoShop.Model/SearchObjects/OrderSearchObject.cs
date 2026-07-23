using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class OrderSearchObject : BaseSearchObject
    {
        public string? CustomerName { get; set; }
        public string? State { get; set; }

        public double? MinTotalAmount { get; set; }
        public double? MaxTotalAmount { get; set; }

        public DateTime? MinOrderDate { get; set; }
        public DateTime? MaxOrderDate { get; set; }
        public DateTime? MinShippingDate { get; set; }
        public DateTime? MaxShippingDate { get; set; }
        public bool? HasDiscount { get; set; } 
        public bool? IncludeItems { get; set; } 
    }

}
