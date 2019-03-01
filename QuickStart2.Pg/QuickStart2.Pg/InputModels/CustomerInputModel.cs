using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Pg;
using QuickStart2.Pg.Models;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.InputModels
{
    public class CustomerInputModel
    {
        [MapToPgVarchar("Name", 255)]
        public string Name { get; set; }

        [MapToPgSmallint("customertypeid")]
        public CustomerModel.CustomerType Type { get; set; }

        public List<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public List<ShardKey> Contacts { get; set; } = new List<ShardKey>();
    }
}
