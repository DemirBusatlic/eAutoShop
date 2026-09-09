using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class OrderModel
    {
        public int Id { get; set; }

        public int? CustomerId { get; set; }

        public string Username { get; set; } = null!;

        public DateTime OrderDate { get; set; }

        public DateTime? ShippingDate { get; set; }

        public double TotalAmount { get; set; }

        public string State { get; set; } = null!;

        public int CityId { get; set; }

        public string ShippingCity { get; set; } = null!;

        public string ShippingAddress { get; set; } = null!;

        public string ShippingPostalCode { get; set; } = null!;
    }
}
