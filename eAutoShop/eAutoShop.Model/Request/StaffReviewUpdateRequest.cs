using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace eAutoShop.Model.Request
{
    public class StaffReviewUpdateRequest
    {
        [Required(ErrorMessage = "This field can not be empty.")]
        [Range(1, 5, ErrorMessage = "The rating number can be in a range from 1 to 5.")]
        public int Rating { get; set; }

        [MaxLength(1000, ErrorMessage = "The comment can't have more than 1000 characters.")]
        public string? Comment { get; set; }
    }
}
