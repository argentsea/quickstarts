using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Sql;
using System.Collections.Generic;
using QuickStart2.Sql.Models;
using QuickStart2.Sql.InputModels;
using Microsoft.SqlServer.Server;
using ShardKey = ArgentSea.ShardKey<byte, int>;


namespace QuickStart2.Sql.Stores
{
    internal static class DataProcedures
    {
        //This is a COMPREHENSIVE list of stored procedure names.
        //You can use the reference count to determine what is still in use (and where).
        public static string CustomerGet { get => @"rd.CustomerGet"; }
        public static string ContactsGet { get => @"rd.ContactsGet "; }
        public static string CustomerCreate { get => @"wt.CustomerCreate"; }
        public static string CustomerList { get => @"rd.CustomerList"; }
        public static string CustomerSave { get => @"wt.CustomerSave"; }
        public static string CustomerDelete { get => @"wt.CustomerDelete"; }
        // ...
    }

    public class CustomerStore
    {
        //private readonly SqlShardSets<byte>.ShardSet _shardSet;
        private readonly ShardSets.ShardSet _shardSet;
        private readonly ILogger<CustomerStore> _logger;
        private const char oCUSTOMER = 'c';

        //public CustomerStore(ShardSetsBase<byte, SqlShardConnectionOptions<byte>> shardSets, ILogger<CustomerStore> logger)
        public CustomerStore(ShardSets shardSets, ILogger<CustomerStore> logger)
        {
            _shardSet = shardSets["Customers"];
            _logger = logger;
        }

        public async Task<CustomerModel> GetCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            var prms = new QueryParameterCollection()
                .AddSqlIntInputParameter("@CustomerId", customerKey.RecordId)
                .CreateOutputParameters<CustomerModel>(_logger);
            var customer = await _shardSet[customerKey].Read.MapOutputAsync<CustomerModel>(DataProcedures.CustomerGet, prms, cancellation);
            if (customer is null && _shardSet[customerKey].Read.ConnectionString != _shardSet[customerKey.ShardId].Write.ConnectionString)
            {
                // if we have id, we can assume that record exists. Therefore Null may be do to replication latency. Retry read on Write connection.
                customer = await _shardSet[customerKey].Write.MapOutputAsync<CustomerModel>("ws.GetCustomer", prms, cancellation);
            }
            return customer;
        }
        public async Task<IList<CustomerListItem>> ListCustomers(CancellationToken cancellation)
        {
            var cust = await _shardSet.ReadAll.MapListAsync<CustomerListItem>(DataProcedures.CustomerList, new QueryParameterCollection(), cancellation);
            return cust;
        }
        public async Task<ShardKey> CreateCustomer(CustomerInputModel customer, CancellationToken cancellation)
        {
            var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
            var contactRecords = new List<SqlDataRecord>();
            customer.Contacts.ForEach(x =>
            {
                var cnt = new SqlDataRecord(metaData);
                cnt.SetByte(0, x.ShardId);
                cnt.SetInt32(1, x.RecordId);
                contactRecords.Add(cnt);
            });

            var prms = new QueryParameterCollection()
                .AddSqlIntOutputParameter("@CustomerId")
                .CreateInputParameters<CustomerInputModel>(customer, _logger)
                .AddSqlTableValuedParameter<LocationModel>("@Locations", customer.Locations, _logger)
                .AddSqlTableValuedParameter("@Contacts", contactRecords);
            await _shardSet.DefaultShard.Write.RunAsync(DataProcedures.CustomerCreate, prms, "@ShardId", cancellation);
            return new ShardKey(oCUSTOMER, _shardSet.DefaultShard.ShardId, (int)prms["@CustomerId"].Value);
        }
        public async Task SaveCustomer(CustomerModel customer, CancellationToken cancellation)
        {
            var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
            var contactRecords = new List<SqlDataRecord>();
            customer.Contacts.ForEach(x =>
            {
                var cnt = new SqlDataRecord(metaData);
                cnt.SetByte(0, x.ContactKey.ShardId);
                cnt.SetInt32(1, x.ContactKey.RecordId);
                contactRecords.Add(cnt);
            });

            var prms = new QueryParameterCollection()
                .CreateInputParameters<CustomerModel>(customer, _logger)
                .AddSqlTableValuedParameter<LocationModel>("@Locations", customer.Locations, _logger)
                .AddSqlTableValuedParameter("@Contacts", contactRecords);
            await _shardSet.DefaultShard.Write.RunAsync(DataProcedures.CustomerSave, prms, "@ShardId", cancellation);
        }
        public async Task DeleteCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            if (customerKey.Origin.SourceIndicator != oCUSTOMER)
            {
                throw new System.Exception("The request to delete a customer failed because this is not a customer key.");
            }
            var prms = new QueryParameterCollection()
                .AddSqlIntInputParameter("@CustomerId", customerKey.RecordId)
                .AddSqlTinyIntInputParameter("@CustomerId", customerKey.ShardId);
            await _shardSet.Write.RunAsync(DataProcedures.CustomerDelete, prms, cancellation); //Deleting on all shards, as their may be foreign Contact references to this Customer
        }
    }
}
