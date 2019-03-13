using ArgentSea;

namespace QuickStart2.Sql
{
    public static class Queries
    {
        //This is a COMPREHENSIVE list of stored procedure names.
        //You can use the reference count to determine what is still in use (and where).
        public static QueryProcedure ContactsGet => new QueryProcedure("rd.ContactsGet", new[] { "@CustomerShardId", "@CustomerId" });

        public static QueryProcedure ContactCustomersDelete => new QueryProcedure("wt.ContactCustomersDelete", new[] { "@CustomerShardId", "@CustomerId" });

        public static QueryProcedure ContactCustomersCreate => new QueryProcedure("wt.ContactCustomersCreate", new[] { "@CustomerShardId", "@CustomerId", "@Contacts" });

        public static QueryProcedure CustomerCreate => new QueryProcedure("wt.CustomerCreate", new[] { "@ShardId", "@CustomerId", "@CustomerTypeId", "@Name", "@Contacts", "@Locations" });

        public static QueryProcedure CustomerDelete => new QueryProcedure("wt.CustomerDelete", new[] { "@CustomerShardId", "@CustomerId" });

        public static QueryProcedure CustomerGet => new QueryProcedure("rd.CustomerGet", new[] { "@CustomerId", "@CustomerTypeId", "@Name" });

        public static QueryProcedure CustomerList => new QueryProcedure("rd.CustomerList");

        public static QueryProcedure CustomerSave => new QueryProcedure("wt.CustomerSave", new[] { "@CustomerId", "@Name", "@CustomerTypeId", "@Contacts", "@Locations" });

        public static string[] CustomerLocationType = new[] { "LocationId", "LocationTypeId", "StreetAddress", "Locality", "Region", "PostalCode", "Iso3166", "Latitude", "Longitude" };

    }
}
