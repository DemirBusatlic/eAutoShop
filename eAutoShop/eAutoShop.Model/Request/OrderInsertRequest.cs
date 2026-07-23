using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class OrderInsertRequest
    {
        public string? Username { get; set; }
        public bool UserAddress { get; set; }
        public int? CityId { get; set; }
        public string? ShippingAddress { get; set; }
        public string? ShippingPostalCode { get; set; }
        public List<ProductOrderRequest> Product { get; set; }
    }
}
