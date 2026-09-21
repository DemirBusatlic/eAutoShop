using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Helpers
{
    public class OrderStates
    {
        public const string Initial = "initial";
        public const string MissingPayment = "missingpayment";
        public const string OnHold = "onhold";
        public const string Accepted = "accepted";
        public const string Rejected = "rejected";
        public const string Cancelled = "cancelled";
        public const string Completed = "completed";
    }
}
