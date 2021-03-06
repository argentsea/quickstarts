﻿using ArgentSea;
using ArgentSea.Sql;
using System.ComponentModel.DataAnnotations;
using ShardChild = ArgentSea.ShardChild<byte, int, short>;

namespace QuickStart2.Sql.Models
{
    public class LocationModel : IKeyedChildModel<byte, int, short>
    {

        public enum LocationType : byte
        {
            RetailStore = 1,
            DriveThrough = 2,
            Warehouse = 3,
            Partner = 4
        }

        [MapShardChild(DataOrigins.Location, "CustomerId", "LocationId")]
        [MapToSqlInt("CustomerId", true)]
        [MapToSqlSmallInt("LocationId", true)]
        public ShardChild Key { get; set; }

        [MapToSqlTinyInt("LocationTypeId")]
        public LocationType Type { get; set; }

        [Required]
        [StringLength(255)]
        [MapToSqlNVarChar("StreetAddress", 255)]
        public string StreetAddress { get; set; }

        [Required]
        [StringLength(100)]
        [MapToSqlNVarChar("Locality", 100)]
        public string Locality { get; set; }

        [Required]
        [StringLength(100)]
        [MapToSqlNVarChar("Region", 100)]
        public string Region { get; set; }

        [StringLength(25)]
        [MapToSqlNVarChar("PostalCode", 25)]
        public string PostalCode { get; set; }

        [StringLength(2, MinimumLength = 2)]
        [MapToSqlNChar("Iso3166", 2)]
        public string Iso3166 { get; set; }

        [MapToModel]
        public CoordinatesModel Coordinates { get; set; }

    }
}
