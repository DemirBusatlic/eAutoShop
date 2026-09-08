using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
   
        public class OrderBasicInfoModel
        {
            public string Username { get; set; } = null!;

            public DateTime OrderDate { get; set; }

            public DateTime? ShippingDate { get; set; }

            public string State { get; set; } = null!;

            public List<string> Items { get; set; } = new List<string>();
        }
  
}
