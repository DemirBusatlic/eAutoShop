using eAutoShop.Model.Exceptions;

namespace eAutoShop.Services.Helpers
{
    public static class ImageValidator
    {
        private const int MaximumImageSize = 5 * 1024 * 1024;

        public static byte[] Parse(string image)
        {
            try
            {
                var commaIndex = image.IndexOf(',');
                if (commaIndex >= 0)
                    image = image[(commaIndex + 1)..];

                var bytes = Convert.FromBase64String(image);
                if (bytes.Length == 0 || bytes.Length > MaximumImageSize)
                    throw new UserException("Slika mora biti manja od 5 MB.");

                var isPng = bytes.Length >= 8 &&
                    bytes[0] == 0x89 && bytes[1] == 0x50 &&
                    bytes[2] == 0x4E && bytes[3] == 0x47 &&
                    bytes[4] == 0x0D && bytes[5] == 0x0A &&
                    bytes[6] == 0x1A && bytes[7] == 0x0A;

                var isJpeg = bytes.Length >= 3 &&
                    bytes[0] == 0xFF && bytes[1] == 0xD8 &&
                    bytes[2] == 0xFF;

                if (!isPng && !isJpeg)
                    throw new UserException("Dozvoljene su samo PNG i JPEG slike.");

                return bytes;
            }
            catch (UserException)
            {
                throw;
            }
            catch
            {
                throw new UserException("Slika nije u ispravnom Base64 formatu.");
            }
        }
    }
}