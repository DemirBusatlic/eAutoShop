using eAutoShop.Model.Model;
using eAutoShop.Worker.Interfaces;
using System.Net;
using System.Net.Mail;
using System.Text;

namespace eAutoShop.Worker.Services
{
    public class EmailService : IEmailService
    {
        private readonly string _smtpHost;
        private readonly int _smtpPort;
        private readonly bool _useSsl;
        private readonly string? _smtpUsername;
        private readonly string? _smtpPassword;
        private readonly string _fromEmail;
        private readonly string _fromName;

        public EmailService(IConfiguration configuration)
        {
            _smtpHost = configuration["SMTP_HOST"] ?? throw new InvalidOperationException("SMTP_HOST is not configured.");

            _smtpPort = int.TryParse(configuration["SMTP_PORT"],out var smtpPort)? smtpPort: 1025;

            _useSsl = bool.TryParse(configuration["SMTP_USE_SSL"], out var useSsl) && useSsl;

            _smtpUsername = configuration["SMTP_USERNAME"];
            _smtpPassword = configuration["SMTP_PASSWORD"];

            _fromEmail = configuration["SMTP_FROM_EMAIL"] ?? "no-reply@eautoshop.local";

            _fromName = configuration["SMTP_FROM_NAME"] ?? "eAutoShop";
        }

        public async Task SendPasswordResetEmail(PasswordResetEmailModel notification)
        {
            if (string.IsNullOrWhiteSpace(notification.Email))
            {
                throw new InvalidOperationException("Recipient email is missing.");
            }

            if (string.IsNullOrWhiteSpace(notification.Code))
            {
                throw new InvalidOperationException("Password reset code is missing.");
            }

            using var message = new MailMessage
            {
                From = new MailAddress(_fromEmail, _fromName,Encoding.UTF8),
                Subject = "eAutoShop - reset lozinke",
                SubjectEncoding = Encoding.UTF8,
                BodyEncoding = Encoding.UTF8,
                IsBodyHtml = false,
                Body =$"Pozdrav {notification.RecipientName},\n\n" + "Zaprimili smo zahtjev za resetovanje lozinke.\n\n" + $"Vaš kod za reset lozinke je: {notification.Code}\n\n" + "Kod vrijedi 15 minuta i može se iskoristiti samo jednom.\n\n" + "Ako niste zatražili reset lozinke, " + "zanemarite ovu poruku.\n\n" + "eAutoShop"
            };

            message.To.Add(notification.Email);

            using var smtpClient = new SmtpClient(_smtpHost,_smtpPort)
            {
                EnableSsl = _useSsl,
                DeliveryMethod = SmtpDeliveryMethod.Network,
                UseDefaultCredentials = false
            };

            if (!string.IsNullOrWhiteSpace(_smtpUsername))
            {
                smtpClient.Credentials = new NetworkCredential(_smtpUsername, _smtpPassword);
            }

            await smtpClient.SendMailAsync(message);
        }
    }
}