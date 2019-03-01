using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;

namespace QuickStart2.Pg.Models
{
    public class CoordinatesModel
    {
        [Range(-90, 90.0)]
        [MapToPgDouble("latitude")]
        public double Latitude { get; set; }

        [Range(-180, 180.0)]
        [MapToPgDouble("longitude")]
        public double Longitude { get; set; }
    }
}
