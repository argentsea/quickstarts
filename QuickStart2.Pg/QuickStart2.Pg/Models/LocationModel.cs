using ArgentSea;
using ArgentSea.Pg;
using ShardChild = ArgentSea.ShardChild<short, int, short>;

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
        [MapToPgInteger("CustomerId")]
        [MapToPgSmallint("LocationId")]
        public ShardChild CustomerLocationKey { get; set; }

        [MapToPgSmallint("LocationTypeId")]
        public LocationType Type { get; set; }

        [MapToPgVarchar("StreetAddress", 255)]
        public string StreetAddress { get; set; }

        [MapToPgVarchar("Locality", 100)]
        public string Locality { get; set; }

        [MapToPgVarchar("Region", 100)]
        public string Region { get; set; }

        [MapToPgVarchar("PostalCode", 25)]
        public string PostalCode { get; set; }

        [MapToPgVarchar("Iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; } = new CoordinatesModel();

    }
}
