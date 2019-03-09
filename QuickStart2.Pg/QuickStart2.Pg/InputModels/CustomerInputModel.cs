using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Pg;
using QuickStart2.Pg.Models;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.InputModels
{
    public class CustomerInputModel
    {
        [Required]
        [StringLength(255)]
        [MapToPgVarchar("name", 255)]
        public string Name { get; set; }

        [MapToPgSmallint("customertypeid")]
        public CustomerModel.CustomerType Type { get; set; }

        public List<LocationInputModel> Locations { get; set; } = new List<LocationInputModel>();

        public List<ShardKey> Contacts { get; set; } = new List<ShardKey>();
    }
}
