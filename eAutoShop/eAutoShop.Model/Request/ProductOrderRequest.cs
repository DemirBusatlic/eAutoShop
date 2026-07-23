using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class ProductOrderRequest
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
