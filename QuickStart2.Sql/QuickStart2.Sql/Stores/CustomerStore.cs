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
    public class CustomerStore
    {
        private readonly ShardSets.ShardSet _shardSet;
        private readonly ILogger<CustomerStore> _logger;

        public CustomerStore(ShardSets shardSets, ILogger<CustomerStore> logger)
        {
            _shardSet = shardSets["Customers"];
            _logger = logger;
        }

        public async Task<CustomerModel> GetCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            customerKey.ThrowIfInvalidOrigin(DataOrigins.Customer);
            var prms = new ParameterCollection()
                .AddSqlIntInputParameter("@CustomerId", customerKey.RecordId)
                .CreateOutputParameters<CustomerModel>(_logger);
            var result = await _shardSet[customerKey].Read.MapOutputAsync<CustomerModel, LocationModel, ContactListItem>(Queries.CustomerGet, prms, cancellation);
            if (!(result is null))
            {
                // Get contact data from foreign shards, if any
                var foreignShards = ShardKey<byte, int>.ShardListForeign(customerKey.ShardId, result.Contacts);
                if (foreignShards.Count > 0)
                {
                    prms.AddSqlTinyIntInputParameter("@CustomerShardId", customerKey.ShardId);
                    var foreignContacts = await _shardSet.ReadAll.MapListAsync<ContactListItem>(Queries.ContactsGet, prms, foreignShards, cancellation);
                    result.Contacts = ShardKey.Merge(result.Contacts, foreignContacts);
                }
            }
            return result;
        }
        public async Task<IList<CustomerListItem>> ListCustomers(CancellationToken cancellation)
        {
            var cust = await _shardSet.ReadAll.MapListAsync<CustomerListItem>(Queries.CustomerList, new ParameterCollection(), cancellation);
            return cust;
        }
        public async Task<ShardKey> CreateCustomer(CustomerInputModel customer, CancellationToken cancellation)
        {
            AssignLocationIdSequence(customer.Locations);
            var contactRecords = MakeRecordKeyUDTs(customer.Contacts);
            var prms = new ParameterCollection()
                .AddSqlIntOutputParameter("@CustomerId")
                .AddSqlTinyIntInputParameter("@ShardId", _shardSet.DefaultShard.ShardId)
                .CreateInputParameters(customer, _logger)
                .AddSqlTableValuedParameter("@Locations", customer.Locations, _logger)
                .AddSqlTableValuedParameter("@Contacts", contactRecords);
            var custKey = await _shardSet.DefaultShard.Write.ReturnValueAsync<int>(Queries.CustomerCreate, DataOrigins.Customer, "@CustomerId", prms, cancellation);
            try
            {   // if there are any foreign shards, save those records into their respective shard.
                var foreignShards = ShardKey.ShardListForeign(custKey.ShardId, customer.Contacts);
                if (foreignShards.Count > 0)
                {
                    var contactPrms = new ParameterCollection()
                        .AddSqlTinyIntInputParameter("@CustomerShardId", custKey.ShardId)
                        .AddSqlIntInputParameter("@CustomerId", custKey.RecordId)
                        .AddSqlTableValuedParameter("@Contacts", contactRecords);
                    await _shardSet.Write.RunAsync(Queries.ContactCustomersCreate, contactPrms, foreignShards, cancellation);
                }
                return custKey;
            }
            catch
            {
                // revert
                await DeleteCustomer(custKey, default(CancellationToken));
                throw;
            }

        }
        public async Task UpdateCustomer(CustomerModel customer, CancellationToken cancellation)
        {
            ValidateNoDuplicateLocationKeys(customer.Key, customer.Locations);
            //save the new customer record into the default shard 
            var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
            var contactRecords = MakeRecordKeyUDTs<ContactListItem>(customer.Contacts);

            var prms = new ParameterCollection()
                .CreateInputParameters<CustomerModel>(customer, _logger)
                .AddSqlTableValuedParameter("@Locations", customer.Locations, Queries.CustomerLocationType, _logger)
                .AddSqlTableValuedParameter("@Contacts", contactRecords);
            await _shardSet.DefaultShard.Write.RunAsync(Queries.CustomerSave, prms, cancellation);

            // if there are any foreign shards, save those records into their respective shard.
            var foreignShards = ShardKey.ShardListForeign(customer.Key.ShardId, customer.Contacts);
            if (foreignShards.Count > 0)
            {
                var contactPrms = new ParameterCollection()
                    .AddSqlTinyIntInputParameter("@CustomerShardId", customer.Key.ShardId)
                    .AddSqlIntInputParameter("@CustomerId", customer.Key.RecordId)
                    .AddSqlTableValuedParameter("@Contacts", contactRecords);
                await _shardSet.Write.RunAsync(Queries.ContactCustomersCreate, contactPrms, foreignShards, cancellation);
            }
        }
        public async Task DeleteCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            customerKey.ThrowIfInvalidOrigin(DataOrigins.Customer);
            var customerPrms = new ParameterCollection()
                .AddSqlIntInputParameter("@CustomerId", customerKey.RecordId)
                .AddSqlTinyIntInputParameter("@CustomerShardId", customerKey.ShardId);
            await _shardSet.Write.RunAsync(Queries.CustomerDelete, customerPrms, cancellation); //Deleting on all shards, as their may be foreign Contact references to this Customer
            var shards = await _shardSet[customerKey].Write.ListAsync<byte>(Queries.CustomerDelete, customerPrms, "contactshardid", cancellation);
            if (shards.Count > 0)
            {
                var foreignShards = new ShardsValues<byte>();
                foreach (var shd in shards)
                {
                    foreignShards.Add(shd);
                }
                await _shardSet.Write.RunAsync(Queries.ContactCustomersDelete, customerPrms, foreignShards, cancellation);
            }
        }
        private void AssignLocationIdSequence(IList<LocationInputModel> locations)
        {
            for (var i = (short)1; i <= locations.Count; i++)
            {
                locations[i - 1].Sequence = i;
            }
        }
        private void ValidateNoDuplicateLocationKeys(ShardKey custKey, IList<LocationModel> locations)
        {
            short maxId = 0;
            for (var i = 0; i < locations.Count; i++)
            {
                if (locations[i].Key.ChildId > maxId)
                {
                    maxId = locations[i].Key.ChildId;
                }
                for (var j = 0; j < locations.Count; j++)
                {
                    if (i != j && locations[i].Key == locations[j].Key)
                    {
                        throw new System.Exception("Multiple location records have the same key value. The data cannot be saved.");
                    }
                }
            }
            foreach (var loc in locations)
            {
                if (loc.Key == ShardChild<byte, int, short>.Empty)
                {
                    maxId++;
                    var key = new ShardChild<byte, int, short>(custKey, maxId);
                    loc.Key = key;
                }
            }
        }
        private List<SqlDataRecord> MakeRecordKeyUDTs(IList<ShardKey> records) //RecordKey is a SQL UDT.
        {
            var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
            var result = new List<SqlDataRecord>();
            foreach (var key in records)
            {
                var cnt = new SqlDataRecord(metaData);
                cnt.SetByte(0, key.ShardId);
                cnt.SetInt32(1, key.RecordId);
                result.Add(cnt);
            }
            return result;
        }
        private List<SqlDataRecord> MakeRecordKeyUDTs<TModel>(IList<TModel> records) where TModel : IKeyedModel<byte, int> //RecordKey is a SQL UDT.
        {
            var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
            var result = new List<SqlDataRecord>();
            foreach (var obj in records)
            {
                var cnt = new SqlDataRecord(metaData);
                cnt.SetByte(0, obj.Key.ShardId);
                cnt.SetInt32(1, obj.Key.RecordId);
                result.Add(cnt);
            }
            return result;
        }
    }
}
