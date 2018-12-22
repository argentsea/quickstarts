using ArgentSea;
using ArgentSea.Sql;
using ShardChild = ArgentSea.ShardChild<byte, int, short>;

namespace QuickStart2.Sql.Models
{
    public class LocationModel
    {

        public enum LocationType : byte
        {
            RetailStore = 1,
            DriveThrough = 2,
            Warehouse = 3,
            Partner = 4
        }

        [MapShardChild('L', "CustomerId", "LocationId")]
        [MapToSqlInt("CustomerId")]
        [MapToSqlSmallInt("LocationId")]
        public ShardChild CustomerLocatonKey { get; set; }

        [MapToSqlTinyInt("LocationTypeId")]
        public LocationType Type { get; set; }

        [MapToSqlNVarChar("StreetAddress", 255)]
        public string StreetAddress { get; set; }

        [MapToSqlNVarChar("Locality", 100)]
        public string Locality { get; set; }

        [MapToSqlNVarChar("Region", 100)]
        public string Region { get; set; }

        [MapToSqlNVarChar("PostalCode", 25)]
        public string PostalCode { get; set; }

        [MapToSqlNChar("Iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; } = new CoordinatesModel();

    }
}
