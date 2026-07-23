using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class OrderModel
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public DateTime OrderDate { get; set; }
        public DateTime? ShippingDate { get; set; }
        public double TotalAmount { get; set; }
        public double ClientDiscountValue { get; set; }
        public string State { get; set; }
        public int CityId { get; set; }
        public string ShippingCity { get; set; }
        public string ShippingAddress { get; set; }
        public string ShippingPostalCode { get; set; }
    }
}
