using ArgentSea;
using ArgentSea.Pg;
using QuickStart2.Pg.Models;
using System.ComponentModel.DataAnnotations;

namespace QuickStart2.Pg.InputModels
{
    public class LocationInputModel
    {
        [MapToPgSmallint("locationid")]
        public short Sequence { get; set; }

        [MapToPgSmallint("locationtypeid")]
        public LocationModel.LocationType Type { get; set; }

        [Required]
        [StringLength(255)]
        [MapToPgVarchar("streetaddress", 255)]
        public string StreetAddress { get; set; }

        [Required]
        [StringLength(100)]
        [MapToPgVarchar("locality", 100)]
        public string Locality { get; set; }

        [Required]
        [StringLength(100)]
        [MapToPgVarchar("region", 100)]
        public string Region { get; set; }

        [StringLength(25)]
        [MapToPgVarchar("postalcode", 25)]
        public string PostalCode { get; set; }

        [StringLength(2, MinimumLength = 2)]
        [MapToPgVarchar("iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; } = new CoordinatesModel();
    }
}
