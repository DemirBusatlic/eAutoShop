using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class StaffReviewSearchObject : BaseSearchObject
    {
        public int? Rating { get; set; }

        public int? UserId { get; set; }

        public int? EmployeeId { get; set; }

        public int? AppointmentId { get; set; }

        public string? CommentFTS { get; set; }
    }
}
