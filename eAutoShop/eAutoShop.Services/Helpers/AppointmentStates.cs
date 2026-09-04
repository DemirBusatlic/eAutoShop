using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Helpers
{
    public static class AppointmentStates
    {
        public const string Initial = "initial";
        public const string Pending = "pending";
        public const string Confirmed = "confirmed";
        public const string Ongoing = "ongoing";
        public const string Rejected = "rejected";
        public const string Cancelled = "cancelled";
        public const string Completed = "completed";
    }

}
