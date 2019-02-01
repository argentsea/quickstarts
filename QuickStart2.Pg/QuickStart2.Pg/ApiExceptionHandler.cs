// Modified from: https://dejanstojanovic.net/aspnet/2018/may/error-handling-in-aspnet-core/

using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.ComponentModel.DataAnnotations;

namespace QuickStart2.Pg
{
    internal class LowercaseContractResolver : DefaultContractResolver
    {
        protected override string ResolvePropertyName(string propertyName)
        {
            return propertyName.ToLower();
        }
    }

    public class ErrorModel
    {
        public ErrorModel(System.Exception exception)
        {
            this.Error = new ApiException(exception.GetType().Name, exception.Message)
            {
                Target = $"{exception.TargetSite.ReflectedType.FullName}.{exception.TargetSite.Name}"
            };
            if (exception.InnerException != null)
            {
                this.Error.InnerError = new InnerApiException(exception.InnerException);
            }
        }
        public ApiException Error { get; set; }
        public String ToJson()
        {
            return JsonConvert.SerializeObject(this, Formatting.None, new JsonSerializerSettings() { ContractResolver = new LowercaseContractResolver() });
        }
    }

    public class ApiException
    {
        public ApiException(String code, String message)
        {
            this.Code = code;
            this.Message = message;
        }

        [Required]
        public String Code { get; set; }

        [Required]
        public String Message { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public String Target { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public IEnumerable<Exception> Details { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public InnerApiException InnerError { get; set; }
    }

    public class InnerApiException
    {
        public InnerApiException(System.Exception exception)
        {
            this.Code = exception.GetType().Name;
            if (exception.InnerException != null)
            {
                this.InnerError = new InnerApiException(exception.InnerException);
            }
        }

        [Required]
        public String Code { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public InnerApiException InnerError { get; set; }
    }

}
