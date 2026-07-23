using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class PaymentResponse
    {
        public string PaymentIntentId { get; set; }
        public string Message { get; set; }
    }
}
