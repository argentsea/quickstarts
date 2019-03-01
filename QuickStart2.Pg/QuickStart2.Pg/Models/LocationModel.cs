using ArgentSea;
using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;
using ShardChild = ArgentSea.ShardChild<short, int, short>;

namespace QuickStart2.Pg.Models
{
    public class LocationModel : IKeyedChildModel<short, int, short>
    {

        public enum LocationType : byte
        {
            RetailStore = 1,
            DriveThrough = 2,
            Warehouse = 3,
            Partner = 4
        }

        [MapShardChild(DataOrigins.Location, "customerid", "locationid")]
        [MapToPgInteger("customerid")]
        [MapToPgSmallint("locationid")]
        public ShardChild Key { get; set; }

        [MapToPgSmallint("locationtypeid")]
        public LocationType Type { get; set; }

        [Required]
        [MapToPgVarchar("streetaddress", 255)]
        public string StreetAddress { get; set; }

        [Required]
        [MapToPgVarchar("locality", 100)]
        public string Locality { get; set; }

        [Required]
        [MapToPgVarchar("region", 100)]
        public string Region { get; set; }

        [MapToPgVarchar("postalcode", 25)]
        public string PostalCode { get; set; }

        [StringLength(2, MinimumLength = 2)]
        [MapToPgVarchar("iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; } = new CoordinatesModel();

    }
}
