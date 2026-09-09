using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class OrderUpdateRequest
    {
        [Range(1, int.MaxValue)]
        public int? CityId { get; set; }
        [MaxLength(255)]
        public string? ShippingAddress { get; set; }
        [MaxLength(20)]
        public string? ShippingPostalCode { get; set; }
    }
}