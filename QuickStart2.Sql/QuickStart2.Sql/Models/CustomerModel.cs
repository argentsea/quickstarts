using System.Collections.Generic;
using ArgentSea;
using ArgentSea.Sql;
using System.ComponentModel.DataAnnotations;

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

        [Required]
        public IList<LocationModel> Locations { get; set; } = new List<LocationModel>();

        public IList<ContactListItem> Contacts { get; set; } = new List<ContactListItem>();
    }
}
