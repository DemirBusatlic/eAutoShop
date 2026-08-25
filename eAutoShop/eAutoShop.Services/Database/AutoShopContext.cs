using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Database;

public partial class AutoShopContext : DbContext
{
    public AutoShopContext()
    {
    }

    public AutoShopContext(DbContextOptions<AutoShopContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Appointment> Appointments { get; set; }

    public virtual DbSet<AppointmentDetail> AppointmentDetails { get; set; }

    public virtual DbSet<AuthToken> AuthTokens { get; set; }

    public virtual DbSet<AutoShopService> AutoShopServices { get; set; }

    public virtual DbSet<CarManufacturer> CarManufacturers { get; set; }

    public virtual DbSet<CarModel> CarModels { get; set; }

    public virtual DbSet<City> Cities { get; set; }

    public virtual DbSet<Order> Orders { get; set; }

    public virtual DbSet<OrderItem> OrderItems { get; set; }

    public virtual DbSet<Product> Products { get; set; }

    public virtual DbSet<ProductCategory> ProductCategories { get; set; }

    public virtual DbSet<ProductReview> ProductReviews { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<ServiceType> ServiceTypes { get; set; }

    public virtual DbSet<StaffReview> StaffReviews { get; set; }

    public virtual DbSet<User> Users { get; set; }


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Appointment>(entity =>
        {
            entity.Property(e => e.CancellationReason).HasMaxLength(500);
            entity.Property(e => e.PaymentIntentId).HasMaxLength(100);
            entity.Property(e => e.RejectionReason).HasMaxLength(500);
            entity.Property(e => e.ReservationCreatedDate).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.State).HasMaxLength(50);
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.CarModel).WithMany(p => p.Appointments)
                .HasForeignKey(d => d.CarModelId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Appointments_CarModels");

            entity.HasOne(d => d.Customer).WithMany(p => p.AppointmentCustomers)
                .HasForeignKey(d => d.CustomerId)
                .OnDelete(DeleteBehavior.ClientSetNull);

            entity.HasOne(d => d.Employee).WithMany(p => p.AppointmentEmployees).HasForeignKey(d => d.EmployeeId);

            entity.HasOne(d => d.Order).WithMany(p => p.Appointments).HasForeignKey(d => d.OrderId);
        });

        modelBuilder.Entity<AppointmentDetail>(entity =>
        {
            entity.Property(e => e.ServiceName).HasMaxLength(100);

            entity.HasOne(d => d.Appointment).WithMany(p => p.AppointmentDetails)
                .HasForeignKey(d => d.AppointmentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppointmentDetails_Appointments");

            entity.HasOne(d => d.Service).WithMany(p => p.AppointmentDetails)
                .HasForeignKey(d => d.ServiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppointmentDetails_Services");
        });

        modelBuilder.Entity<AuthToken>(entity =>
        {
            entity.Property(e => e.Created).HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.User).WithMany(p => p.AuthTokens)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AuthTokens_Users");
        });

        modelBuilder.Entity<AutoShopService>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK_Services");

            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.ServiceType).WithMany(p => p.AutoShopServices)
                .HasForeignKey(d => d.ServiceTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Services_ServiceTypes");
        });

        modelBuilder.Entity<CarManufacturer>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<CarModel>(entity =>
        {
            entity.Property(e => e.ModelYear).HasMaxLength(10);
            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.CarManufacturer).WithMany(p => p.CarModels)
                .HasForeignKey(d => d.CarManufacturerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CarModels_Manufacturers");
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.Property(e => e.OrderDate).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.PaymentIntentId).HasMaxLength(100);
            entity.Property(e => e.PostalCode).HasMaxLength(20);
            entity.Property(e => e.ShippingAddress).HasMaxLength(255);
            entity.Property(e => e.State).HasMaxLength(50);

            entity.HasOne(d => d.City).WithMany(p => p.Orders)
                .HasForeignKey(d => d.CityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Orders_Cities");

            entity.HasOne(d => d.Customer).WithMany(p => p.OrderCustomers).HasForeignKey(d => d.CustomerId);

            entity.HasOne(d => d.Employee).WithMany(p => p.OrderEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull);
        });

        modelBuilder.Entity<OrderItem>(entity =>
        {
            entity.HasOne(d => d.Order).WithMany(p => p.OrderItems)
                .HasForeignKey(d => d.OrderId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_OrderItems_Orders");

            entity.HasOne(d => d.Product).WithMany(p => p.OrderItems)
                .HasForeignKey(d => d.ProductId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_OrderItems_Products");
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.ProductCategory).WithMany(p => p.Products)
                .HasForeignKey(d => d.ProductCategoryId)
                .HasConstraintName("FK_Products_ProductCategories");

            entity.HasMany(d => d.CarModels).WithMany(p => p.Products)
                .UsingEntity<Dictionary<string, object>>(
                    "ProductCarModel",
                    r => r.HasOne<CarModel>().WithMany()
                        .HasForeignKey("CarModelId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_ProductCarModels_CarModels"),
                    l => l.HasOne<Product>().WithMany()
                        .HasForeignKey("ProductId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_ProductCarModels_Products"),
                    j =>
                    {
                        j.HasKey("ProductId", "CarModelId");
                        j.ToTable("ProductCarModels");
                    });
        });

        modelBuilder.Entity<ProductCategory>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<ProductReview>(entity =>
        {
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.Product).WithMany(p => p.ProductReviews)
                .HasForeignKey(d => d.ProductId)
                .HasConstraintName("FK_ProductReviews_Products");

            entity.HasOne(d => d.User).WithMany(p => p.ProductReviews)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK_ProductReviews_Users");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<ServiceType>(entity =>
        {
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<StaffReview>(entity =>
        {
            entity.HasIndex(
                    e => e.AppointmentId,
                    "UX_StaffReviews_AppointmentId"
                )
                .IsUnique()
                .HasFilter("([AppointmentId] IS NOT NULL)");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Appointment)
                .WithOne(p => p.StaffReview)
                .HasForeignKey<StaffReview>(d => d.AppointmentId)
                .HasConstraintName("FK_StaffReviews_Appointments");

            entity.HasOne(d => d.Employee)
                .WithMany(p => p.StaffReviewEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_StaffReviews_EmployeeId");

            entity.HasOne(d => d.User)
                .WithMany(p => p.StaffReviewUsers)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK_StaffReviews_Users");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.Gender).HasMaxLength(10);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(50);
            entity.Property(e => e.Surname).HasMaxLength(100);
            entity.Property(e => e.Username).HasMaxLength(100);

            entity.HasOne(d => d.City).WithMany(p => p.Users)
                .HasForeignKey(d => d.CityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Users_Cities");

            entity.HasOne(d => d.Role).WithMany(p => p.Users)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Users_Roles");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
