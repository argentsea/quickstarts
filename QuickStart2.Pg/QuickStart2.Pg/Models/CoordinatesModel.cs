using ArgentSea.Pg;

namespace QuickStart2.Pg.Models
{
    public class CoordinatesModel
    {
        [MapToPgDouble("latitude")]
        public double Latitude { get; set; }

        [MapToPgDouble("longitude")]
        public double Longitude { get; set; }
    }
}
