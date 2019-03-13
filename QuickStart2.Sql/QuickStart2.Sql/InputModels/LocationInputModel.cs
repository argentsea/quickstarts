using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ArgentSea;
using ArgentSea.Sql;
using QuickStart2.Sql.Models;
using System.ComponentModel.DataAnnotations;

namespace QuickStart2.Sql.InputModels
{
    public class LocationInputModel
    {
        [MapToSqlSmallInt("LocationId")]
        public short Sequence { get; set; }

        [MapToSqlTinyInt("LocationTypeId")]
        public LocationModel.LocationType Type { get; set; }

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
