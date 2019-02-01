using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Data.Common;
using Npgsql;

namespace QuickStart2.Pg
{
    public class SqlStatement
    {
        private readonly string _commandText;
        private DbParameter[] _prms;

        public SqlStatement(string commandText)
        {
            _commandText = commandText;
            _prms = null;
        }
        public SqlStatement(string commandText, params DbParameter[] parameters)
        {
            _commandText = commandText;
            _prms = parameters;
        }

        public DbParameter[] Parameters { get => _prms; }
    }

    public static class SqlStatements 
    {
        public static SqlStatement GetCustomer { get => new SqlStatement("123", new NpgsqlParameter() { ParameterName = "" }); }

    }

}
