using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Sql;
using QuickStart2.Sql.Models;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.InputModels
{
    public class CustomerInputModel
    {
        [MapToSqlNVarChar("Name", 255)]
        public string Name { get; set; }

        public List<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public List<ShardKey> Contacts { get; set; } = new List<ShardKey>();
    }
}
