using ArgentSea.Sql;

namespace QuickStart2.Sql.Models
{
    public class CoordinatesModel
    {
        [MapToSqlFloat("Latitude")]
        public double Latitude { get; set; }

        [MapToSqlFloat("Longitude")]
        public double Longitude { get; set; }
    }
}
