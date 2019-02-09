using ArgentSea;
using ArgentSea.Pg;
using ShardChild = ArgentSea.ShardChild<short, int, short>;

namespace QuickStart2.Pg.Models
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

        [MapShardChild('L', "customerid", "locationid")]
        [MapToPgInteger("customerid")]
        [MapToPgSmallint("locationid")]
        public ShardChild CustomerLocationKey { get; set; }

        [MapToPgSmallint("locationtypeid")]
        public LocationType Type { get; set; }

        [MapToPgVarchar("streetaddress", 255)]
        public string StreetAddress { get; set; }

        [MapToPgVarchar("locality", 100)]
        public string Locality { get; set; }

        [MapToPgVarchar("region", 100)]
        public string Region { get; set; }

        [MapToPgVarchar("postalcode", 25)]
        public string PostalCode { get; set; }

        [MapToPgVarchar("iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; } = new CoordinatesModel();

    }
}
