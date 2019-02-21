using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Pg;
using System.Collections.Generic;
using QuickStart2.Pg.Models;
using QuickStart2.Pg.InputModels;
using Microsoft.SqlServer.Server;
using ArgentSea.QueryBatch;
using ShardKey = ArgentSea.ShardKey<short, int>;


namespace QuickStart2.Pg.Stores
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
            var prms = new ParameterCollection()
                .AddPgIntegerInputParameter("customerid", customerKey.RecordId);
            var result = await _shardSet[customerKey].Read.MapReaderAsync<CustomerModel, CustomerModel, LocationModel, ContactModel>(Queries.CustomerGet, prms, cancellation);
            var foreignShards = ShardKey<short, int>.ShardListForeign(customerKey.ShardId, result.Contacts);
            if (foreignShards.Count > 0)
            {
                prms.AddPgSmallintInputParameter("shardId", customerKey.ShardId);
                var foreignContacts = await _shardSet.ReadAll.MapListAsync<ContactModel>(Queries.ContactsGet, prms, foreignShards, cancellation);
                ShardKey.Merge<ContactModel>(result.Contacts, foreignContacts);
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
            var prms = new ParameterCollection();
            //KeyQueryBatch<short, int> batch = new KeyQueryBatch<short, int>();
            //batch.Add(customer.Contacts, "tmpContacts", new MapToPgSmallintAttribute("contactshardid"), new MapToPgIntegerAttribute("contactid"));
            //batch.Add(customer.Locations, "tmpLocations");
            //batch.Add(Queries.CustomerSave, DataOrigins.Customer, "", "");
            //var custKey = await _shardSet.DefaultShard.Write.ExecuteBatchAsync(batch, cancellation);
            var batch = new ShardBatch<short, ShardKey<short, int>>()
                .Add(customer.Contacts, "tmpContacts", new MapToPgSmallintAttribute("contactshardid"), new MapToPgIntegerAttribute("contactid"))
                .Add(customer.Locations, "tmpLocations")
                .Add(Queries.CustomerCreate)
                .Add(Queries.CustomerSave, prms, DataOrigins.Customer, "", "");
            var custKey = await _shardSet.DefaultShard.Write.ExecuteBatchAsync(batch, cancellation);

            var batch2 = new ShardBatch<short>();
            return custKey;
        }

        //public async Task SaveCustomer(CustomerModel customer, CancellationToken cancellation)
        //{
        //    var metaData = new SqlMetaData[] { new SqlMetaData("ShardId", System.Data.SqlDbType.TinyInt), new SqlMetaData("RecordId", System.Data.SqlDbType.Int) };
        //    var contactRecords = new List<SqlDataRecord>();
        //    ((List<ContactModel>)customer.Contacts).ForEach(x =>
        //    {
        //        var cnt = new SqlDataRecord(metaData);
        //        cnt.SetInt16(0, x.ContactKey.ShardId);
        //        cnt.SetInt32(1, x.ContactKey.RecordId);
        //        contactRecords.Add(cnt);
        //    });

        //    var prms = new ParameterCollection()
        //        .CreateInputParameters<CustomerModel>(customer, _logger)
        //        .AddSqlTableValuedParameter<LocationModel>("@Locations", customer.Locations, _logger)
        //        .AddSqlTableValuedParameter("@Contacts", contactRecords);
        //    await _shardSet.DefaultShard.Write.RunAsync(Queries.CustomerSave, prms, "@ShardId", cancellation);
        //}
        public async Task DeleteCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            if (customerKey.Origin != DataOrigins.Customer)
            {
                throw new System.Exception("The request to delete a customer failed because this is not a customer key.");
            }
            var prms = new ParameterCollection()
                .AddPgIntegerInputParameter("customerid", customerKey.RecordId)
                .AddPgSmallintInputParameter("shardid", customerKey.ShardId);
            await _shardSet.Write.RunAsync(Queries.CustomerDelete, prms, cancellation); //Deleting on all shards, as their may be foreign Contact references to this Customer
        }
    }
}
