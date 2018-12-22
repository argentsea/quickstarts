using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Sql;

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

        [MapToSqlTinyInt("CustomerTypeId")]
        public CustomerType Type { get; set; }

        public List<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public List<ContactModel> Contacts { get; set; } = new List<ContactModel>();
    }
}
