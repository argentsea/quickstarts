using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ArgentSea;

namespace QuickStart2.Pg
{
    public static class Queries
    {
    public static QueryStatement ContactsGet => _contactsGet.Value;
    private static readonly Lazy<QueryStatement> _contactsGet = QueryStatement.Create("ContactsGet", new[] { "subid" });

    public static QueryStatement CustomerCreate => _customerCreate.Value;
    private static readonly Lazy<QueryStatement> _customerCreate = QueryStatement.Create("CustomerCreate", new[] { "shardid", "customertypeid", "name" });

        public static QueryStatement CustomerDelete => _customerDelete.Value;
        private static readonly Lazy<QueryStatement> _customerDelete = QueryStatement.Create("_customerDelete", new[] { "shardid", "customerid" });

        public static QueryStatement CustomerGet => _customerGet.Value;
        private static readonly Lazy<QueryStatement> _customerGet = QueryStatement.Create("CustomerGet", new[] { "customerid" });

        public static QueryStatement CustomerList => _customerList.Value;
        private static readonly Lazy<QueryStatement> _customerList = QueryStatement.Create("CustomerList");

    public static QueryStatement CustomerSave => _customerSave.Value;
    private static readonly Lazy<QueryStatement> _customerSave = QueryStatement.Create("CustomerSave", new[] { "subid" });
    }
}
