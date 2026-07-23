using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class User
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Surname { get; set; } = null!;

    public string Username { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? PasswordHash { get; set; }

    public byte[]? Image { get; set; }

    public string Phone { get; set; } = null!;

    public string Gender { get; set; } = null!;

    public int CityId { get; set; }

    public int RoleId { get; set; }

    public bool Active { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? Address { get; set; }

    public string? PostalCode { get; set; }

    public virtual ICollection<Appointment> AppointmentCustomers { get; set; } = new List<Appointment>();

    public virtual ICollection<Appointment> AppointmentEmployees { get; set; } = new List<Appointment>();

    public virtual ICollection<AuthToken> AuthTokens { get; set; } = new List<AuthToken>();

    public virtual City City { get; set; } = null!;

    public virtual ICollection<Order> OrderCustomers { get; set; } = new List<Order>();

    public virtual ICollection<Order> OrderEmployees { get; set; } = new List<Order>();

    public virtual ICollection<ProductReview> ProductReviews { get; set; } = new List<ProductReview>();

    public virtual Role Role { get; set; } = null!;

    public virtual ICollection<StaffReview> StaffReviewEmployees { get; set; } = new List<StaffReview>();

    public virtual ICollection<StaffReview> StaffReviewUsers { get; set; } = new List<StaffReview>();
}
