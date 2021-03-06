﻿using ArgentSea;
using ArgentSea.Sql;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class CustomerListItem : IKeyedModel<byte, int>
    {
        [MapShardKey(DataOrigins.Customer, "@CustomerId")]
        [MapToSqlInt("@CustomerId", true)]
        public ShardKey Key { get; set; }

        [Required]
        [StringLength(255, MinimumLength = 2)]
        [MapToSqlNVarChar("@Name", 255, true)]
        public string Name { get; set; }
    }
}
