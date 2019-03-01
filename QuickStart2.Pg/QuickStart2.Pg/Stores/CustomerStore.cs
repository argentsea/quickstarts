using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Pg;
using System.Collections.Generic;
using QuickStart2.Pg.Models;
using QuickStart2.Pg.InputModels;
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
            customerKey.ThrowIfInvalidOrigin(DataOrigins.Customer);
            var prms = new ParameterCollection()
                .AddPgIntegerInputParameter("customerid", customerKey.RecordId);
            var result = await _shardSet[customerKey].Read.MapReaderAsync<CustomerModel, CustomerModel, LocationModel, ContactModel>(Queries.CustomerGet, prms, cancellation);
            // Get data from foreign shards, if any
            var foreignShards = ShardKey<short, int>.ShardListForeign(customerKey.ShardId, result.Contacts);
            if (foreignShards.Count > 0)
            {
                prms.AddPgSmallintInputParameter("shardId", customerKey.ShardId);
                var foreignContacts = await _shardSet.ReadAll.MapListAsync<ContactListItem>(Queries.ContactsGet, prms, foreignShards, cancellation);
                ShardKey.Merge<ContactListItem>(result.Contacts, foreignContacts);
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
            //save the new customer record into the default shard 
            var customerPrms = new ParameterCollection()
                .CreateInputParameters<CustomerInputModel>(customer, _logger)
                .AddPgSmallintInputParameter("shardid", _shardSet.DefaultShard.ShardId);
            var shardBatch = new ShardBatch<short, ShardKey<short, int>>()
                .Add(customer.Contacts, "temp-contacts", new MapToPgSmallintAttribute("contactshardid"), new MapToPgIntegerAttribute("contactid"))
                .Add(customer.Locations, "temp-locations")
                .Add(Queries.CustomerCreate, customerPrms, DataOrigins.Customer, "newcustomerid");
            var custKey = await _shardSet.DefaultShard.Write.RunAsync(shardBatch, cancellation);

            try
            {   // if there are any foreign shards, save those records into their respective shard.
                var foreignShards = ShardKey.ShardListForeign(custKey.ShardId, customer.Contacts);
                if (foreignShards.Count > 0)
                {
                    var contactPrms = new ParameterCollection()
                        .AddPgSmallintInputParameter("customershardid", custKey.ShardId)
                        .AddPgIntegerInputParameter("customerid", custKey.RecordId);
                    var setBatch = new ShardSetBatch<short>()
                        .Add(customer.Contacts, "temp-contacts", new MapToPgSmallintAttribute("contactshardid"), new MapToPgIntegerAttribute("contactid"))
                        .Add(Queries.ContactCustomersCreate, contactPrms);
                    await _shardSet.Write.RunAsync(setBatch, foreignShards, cancellation);
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
            //save the new customer record into the default shard 
            var customerPrms = new ParameterCollection()
                .CreateInputParameters<CustomerModel>(customer, _logger);

            var shardBatch = new ShardBatch<short, object>()
                .Add(customer.Contacts, "temp-contacts")
                .Add(customer.Locations, "temp-locations")
                .Add(Queries.CustomerSave, customerPrms);
            await _shardSet[customer.Key].Write.RunAsync<object>(shardBatch, cancellation);

            // if there are any foreign shards, save those records into their respective shard.
            var foreignShards = ShardKey.ShardListForeign(customer.Key.ShardId, customer.Contacts);
            if (foreignShards.Count > 0)
            {
                var contactPrms = new ParameterCollection()
                    .AddPgSmallintInputParameter("customershardid", customer.Key.ShardId)
                    .AddPgIntegerInputParameter("customerid", customer.Key.RecordId);
                var setBatch = new ShardSetBatch<short>()
                    .Add(customer.Contacts, "temp-contacts")
                    .Add(Queries.ContactCustomersCreate, contactPrms);
                await _shardSet.Write.RunAsync(setBatch, foreignShards, cancellation);
            }
        }

        public async Task DeleteCustomer(ShardKey customerKey, CancellationToken cancellation)
        {
            customerKey.ThrowIfInvalidOrigin(DataOrigins.Customer);
            var customerPrms = new ParameterCollection()
                .AddPgIntegerInputParameter("customerid", customerKey.RecordId)
                .AddPgSmallintInputParameter("shardid", customerKey.ShardId);
            var shards = await _shardSet[customerKey].Write.ListAsync<short>(Queries.CustomerDelete, customerPrms, "contactshardid", cancellation);
            if (shards.Count > 0)
            {
                var foreignShards = new ShardsValues<short>();
                foreach (var shd in shards)
                {
                    foreignShards.Add(shd);
                }
                await _shardSet.Write.RunAsync(Queries.ContactCustomersDelete, customerPrms, foreignShards, cancellation);
            }
        }
    }
}
