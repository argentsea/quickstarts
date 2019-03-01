using ArgentSea.Sql;
using System.ComponentModel.DataAnnotations;

namespace QuickStart2.Sql.Models
{
    public class CoordinatesModel
    {
        [Range(-90, 90.0)]
        [MapToSqlFloat("Latitude")]
        public double Latitude { get; set; }

        [Range(-180, 180.0)]
        [MapToSqlFloat("Longitude")]
        public double Longitude { get; set; }
    }
}
