using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class StaffReviewModel
    {
        public int Id { get; set; }

        public int? UserId { get; set; }

        public int? EmployeeId { get; set; }

        public int? Rating { get; set; }

        public string? Comment { get; set; }

        public DateTime? CreatedAt { get; set; }

        public string? UserName { get; set; }

        public string? EmployeeName { get; set; }
    }
}
