using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Pg;

namespace QuickStart2.Sql.Models
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

        [MapToPgSmallint("CustomerTypeId")]
        public CustomerType Type { get; set; }

        public IList<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public IList<ContactModel> Contacts { get; set; } = new List<ContactModel>();
    }
}
