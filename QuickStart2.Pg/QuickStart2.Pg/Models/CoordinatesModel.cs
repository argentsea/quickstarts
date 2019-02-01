using ArgentSea.Pg;

namespace QuickStart2.Sql.Models
{
    public class CoordinatesModel
    {
        [MapToPgDouble("Latitude")]
        public double Latitude { get; set; }

        [MapToPgDouble("Longitude")]
        public double Longitude { get; set; }
    }
}
