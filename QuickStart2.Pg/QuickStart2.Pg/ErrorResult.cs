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
  ""code"": """);
            sb.Append(statusCode);
            sb.Append(@""",
  ""message"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.Message));
            sb.Append(@""",
  ""target"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode($"{error.TargetSite?.ReflectedType?.FullName}.{error.TargetSite?.Name}", false));
            sb.Append(@""",
  ""details"": [");
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
    }");
                innerEx = innerEx.InnerException;
                if (!(innerEx is null))
                {
                    sb.Append(",");
                }
            }
            sb.Append(@"],
  ""innererror"": {
    ""type"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.GetType().Name, false));
            sb.Append(@""",
    ""trace"": """);
            sb.Append(HttpUtility.JavaScriptStringEncode(error.StackTrace, false));
            sb.Append(@"""
  }
}");
            return sb.ToString();
        }
    }
}
