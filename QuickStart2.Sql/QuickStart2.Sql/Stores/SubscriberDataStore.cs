using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Sql;
using System.Collections.Generic;


namespace QuickStart2.Sql.Stores
{
    internal static class DataProcedures
    {
        //This is a COMPREHENSIVE list of stored procedure names.
        //You can use the reference count to determine what is still in use.
        public static string CustomerAdd { get; } = @"ws.CustomerAdd";
        public static string CustomerList { get; } = @"ws.CustomerList";
        public static string CustomerLocationGet { get; } = @"ws.CustomerLocationGet";
        public static string CustomerLocationDetailsGet { get; } = @"ws.CustomerLocationDetailsGet";
        public static string CustomerLocationsAllByUser { get; } = @"ws.CustomerLocationsAllByUser";
        public static string CustomerLocationsByGroupIDs { get; } = @"ws.CustomerLocationsByGroupIDs";
        // ...
    }

    public class SubscriberStore
    {
        private readonly SqlShardSets.ShardSet _shardSet;

        private readonly ILogger<SubscriberStore> _logger;
        public SubscriberStore(SqlShardSets shardSets, ILogger<SubscriberStore> logger)
        {
            _shardSet = shardSets["Subscribers"];
            _logger = logger;
        }

        private class Subscriber
        {
            
        }

        public async Task<Subscriber> GetSubscriber(ShardKey<byte, int> subscriberKey, CancellationToken cancellation)
        {
            var x = DataProcedures.CustomerAdd;

            var prms = new QueryParameterCollection()
                .AddSqlIntInParameter("@SubId", subscriberKey.RecordId);
            Mapper.MapToOutParameters<Subscriber>(prms, _logger);
            //var sub = await _shardSet[subscriberKey.ShardId].Read..ListAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
            var sub = await _shardSet[subscriberKey.ShardId].Read.QueryAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
            if (sub is null)
            {
                var sub = await _shardSet[subscriberKey.ShardId].Write.QueryAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
            }
            return sub;
        }
        public async Task<List<Subscriber>> ListSubscribers(CancellationToken cancellation)
        {
var prms = new QueryParameterCollection()
    .AddSqlIntInParameter("@TransactionId", transactionId)
    .AddSqlDecimalInParameter("@Amount", amount, 16, 2)
    .AddSqlNVarCharInParameter("@Name", name, 255)
    .AddSqlRealOutParameter("@Temperature");
            var transactionId = prms["@TransactionId"].GetInteger();
            var amount = prms["@Amount"].GetNullableDecimal();
            var name = prms["@Name"].GetString();

prms.AddSqlIntInParameter("@TransactionId", transactionId);
prms.AddSqlDecimalInParameter("@Amount", amount, 16, 2);
prms.AddSqlNVarCharInParameter("@Name", name, 255);
prms.AddSqlRealOutParameter("@Temperature");

            var rdr = new System.Data.SqlClient.SqlDataReader();
            rdr.NextResult();

            _database.GetOutFirstAsync<Order, OrderItems>("dbo.GetOrderDetails", prms, cancellation);
            _database.ReadFirstAsync(Order, OrderItems>("GetOrderDetails", prms, cancellation);

            prms.MapToInParameters<Customer>(customer, logger);
            prms.MapToOutParameters<Customer>(logger);

            var prm = new System.Data.SqlClient.SqlParameter();
            prm.SqlDbType = System.Data.SqlDbType.Int;
            prm.Value = transactionId;
            prms.Add(prm);

            prms.Add()

            var prms = new QueryParameterCollection();
            var sub = await _shardSet.QueryAllAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
            return sub;
        }

        public void Test()
        {

            var prms = new QueryParameterCollection().AddSqlBigIntInParameter("@ID", _id).MapToOutParameters<MyClass>(logger);
            prms.MapToInParameters<MyClass>(myInstance, logger);

            var cmd = new System.Data.SqlClient.SqlCommand();
            var rdr = new System.Data.SqlClient.SqlDataReader();

            var rdr = await cmd.ExecuteReaderAsync(cancellationToken);
            var customers = Mapper.FromDataReader<Customer>(rdr, logger);

            var shardSets = new ShardSets<byte>();
            var shardSet = shardSets[0];

        }

    }
}
