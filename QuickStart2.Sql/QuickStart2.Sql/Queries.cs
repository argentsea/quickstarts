using ArgentSea;

namespace QuickStart2.Sql
{
    public static class Queries
    {
        //This is a COMPREHENSIVE list of stored procedure names.
        //You can use the reference count to determine what is still in use (and where).
        public static QueryProcedure CustomerGet => new QueryProcedure("rd.CustomerGet", null);

        public static QueryProcedure CustomerCreate => new QueryProcedure("wt.CustomerCreate", null);

        public static QueryProcedure CustomerList => new QueryProcedure("rd.CustomerList", null);

        public static QueryProcedure CustomerSave => new QueryProcedure("wt.CustomerSave", null);

        public static QueryProcedure CustomerDelete => new QueryProcedure("wr.CustomerDelete", null);

    }
}
