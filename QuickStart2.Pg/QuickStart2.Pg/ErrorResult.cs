// Based on OASIS standard: http://docs.oasis-open.org/odata/odata-json-format/v4.0/os/odata-json-format-v4.0-os.html#_Toc372793091
// although "code" and "message" largely corresponds to Google's practices also: https://google.github.io/styleguide/jsoncstyleguide.xml#Reserved_Property_Names_in_the_error_object
// The error root is omitted because the error object is implicit (avoids error.error)

using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using System.Web;
using System.Text;

namespace QuickStart2.Pg
{
    public static class ErrorResult
    {
        public static string CaptureToJSON(int statusCode, Exception error)
        {
            var sb = new StringBuilder();

            sb.Append(@"{
  ""error"": {
    ""code"": """);
            sb.Append(statusCode);
            sb.Append(@""",
    ""message"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.Message));
            sb.Append(@""",
    ""target"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode($"{error.TargetSite?.ReflectedType?.FullName}.{error.TargetSite?.Name}", false));
            sb.Append(@""",
    ""innerErrors"": [");
            var innerEx = error.InnerException;
            var iterations = 0;
            while (!(innerEx is null))
            {
                iterations++;
                if (iterations > 10)
                {
                    break;
                }
                sb.Append(@"
      {
        ""code"": """);
                sb.Append(HttpUtility.JavaScriptStringEncode(innerEx.GetType().Name, false)); // SqlException, ArgumentOutOfRangeException, etc.
                sb.Append(@"""
        ""target"": """);
                sb.Append(HttpUtility.JavaScriptStringEncode($"{innerEx.TargetSite?.ReflectedType?.FullName}.{innerEx.TargetSite?.Name}", false));
                sb.Append(@"""
        ""message"": """);
                sb.Append(HttpUtility.JavaScriptStringEncode(innerEx.Message, false));
                sb.Append(@"""
      }
");
                innerEx = innerEx.InnerException;
                if (!(innerEx is null))
                {
                    sb.Append(",");
                }
            }
            sb.Append(@"],
    ""type"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.GetType().Name, false));
            sb.Append(@"""");
            if (error is Npgsql.PostgresException)
            {
                var seperator = string.Empty;
                sb.AppendLine(@",
    ""postgreSQL"": {");
                var pgErr = (Npgsql.PostgresException)error;
                if (!string.IsNullOrEmpty(pgErr.ColumnName))
                {
                    sb.Append($"{ seperator }      \"columnName\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.ColumnName) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.ConstraintName))
                {
                    sb.Append($"{ seperator }      \"constraintName\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.ConstraintName) }\"");
                    seperator = ",\r\n";
                }
                //if (!string.IsNullOrEmpty(pgErr.Data))
                //{
                //    sb.Append($"{ seperator }    \"code\": \"{pgErr.Data}\"");
                //    seperator = ",\r\n";
                //}
                if (!string.IsNullOrEmpty(pgErr.DataTypeName))
                {
                    sb.Append($"{ seperator }      \"dataTypeName\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.DataTypeName) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.Detail))
                {
                    sb.Append($"{ seperator }      \"detail\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Detail) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.Hint))
                {
                    sb.Append($"{ seperator }      \"hing\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Hint) }\"");
                    seperator = ",\r\n";
                }
                if (pgErr.InternalPosition != 0)
                {
                    sb.Append($"{ seperator }      \"internalPosition\": { pgErr.InternalPosition.ToString() }");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.InternalQuery))
                {
                    sb.Append($"{ seperator }      \"internalQuery\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.InternalQuery) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.Line))
                {
                    sb.Append($"{ seperator }      \"line\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Line) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.MessageText))
                {
                    sb.Append($"{ seperator }      \"messageText\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.MessageText) }\"");
                    seperator = ",\r\n";
                }
                if (pgErr.Position != 0)
                {
                    sb.Append($"{ seperator }      \"position\": { pgErr.Position.ToString() }");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.Routine))
                {
                    sb.Append($"{ seperator }      \"routine\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Routine) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.SchemaName))
                {
                    sb.Append($"{ seperator }      \"schemaName\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.SchemaName) }\"");
                    seperator = ",\r\n";
                }
                if (!(pgErr.Statement is null))
                {
                    if (!string.IsNullOrEmpty(pgErr.Statement.SQL))
                    {
                        sb.Append($"{ seperator }      \"statement\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Statement.SQL) }\"");
                        seperator = ",\r\n";
                    }
                    if (!(pgErr.Statement.InputParameters is null))
                    {
                        sb.Append($"{ seperator }      \"parameters\": [");
                        seperator = ",\r\n";
                        foreach (var pgPrm in pgErr.Statement.InputParameters)
                        {
                            var sep2 = string.Empty;
                            sb.Append($"{sep2}        {{");
                            sb.AppendLine($"          \"name\": \"{pgPrm.ParameterName}\",");
                            sb.AppendLine($"          \"type\": \"{pgPrm.NpgsqlDbType.ToString()}\",");
                            sb.AppendLine($"          \"value\": \"{pgPrm.Value.ToString()}\",");
                            sb.Append("        }");
                            sep2 = ",\r\n";
                        }
                        sb.Append($"]");
                    }
                    if (!string.IsNullOrEmpty(pgErr.Statement.SQL))
                    {
                        sb.Append($"{ seperator }      \"sql\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Statement.SQL) }\"");
                        seperator = ",\r\n";
                    }
                }


                if (!string.IsNullOrEmpty(pgErr.TableName))
                {
                    sb.Append($"{ seperator }      \"tableName\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.TableName) }\"");
                    seperator = ",\r\n";
                }
                if (!string.IsNullOrEmpty(pgErr.Where))
                {
                    sb.Append($"{ seperator }      \"where\": \"{ HttpUtility.JavaScriptStringEncode(pgErr.Where) }\"");
                    seperator = ",\r\n";
                }
                sb.Append(@"    }");
            }
            sb.Append(@",
    ""trace"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.StackTrace, false));
            sb.Append(@"""
  }
}");
            return sb.ToString();
        }
    }
}
