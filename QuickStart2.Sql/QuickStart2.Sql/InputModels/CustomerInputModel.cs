using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Sql;
using QuickStart2.Sql.Models;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.InputModels
{
    public class CustomerInputModel
    {
        [Required]
        [StringLength(255)]
        [MapToSqlNVarChar("Name", 255)]
        public string Name { get; set; }

        [MapToSqlTinyInt("CustomerTypeId")]
        public CustomerModel.CustomerType Type { get; set; }

        public List<LocationInputModel> Locations { get; set; } = new List<LocationInputModel>();

        public List<ShardKey> Contacts { get; set; } = new List<ShardKey>();
    }
}
