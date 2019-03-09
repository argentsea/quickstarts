using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class CustomerModel : CustomerListItem
    {
        public enum CustomerType : byte
        {
            WalkIn = 1,
            Subscriber = 2,
            Franchisee = 3,
            Partner = 4
        }

        [MapToPgSmallint("customertypeid")]
        public CustomerType Type { get; set; }

        [Required]
        public IList<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public IList<ContactListItem> Contacts { get; set; } = new List<ContactListItem>();
    }
}
