using System;
using System.Net.Http;
using Xunit;
using Newtonsoft.Json.Linq;
using FluentAssertions;

namespace Quickstart.Test
{
    public class ApiTests
    {
        [Theory]
        [InlineData(1, "Otakar Patton", "2018-Jan-6")]
        [InlineData(2, "Fulbert Sorenson", "2018-Jul-15")]
        [InlineData(3, "Fortunato Paredes", null)]
        [InlineData(4, "Elenora Willoughby", null)]
        [InlineData(5, "Aditya Jerome", "2019-Dec-22")]
        [InlineData(6, "Ivan Dreesen", "2015-Aug-1")]
        public async void TestSubscriber(int subscriberId, string name, string expiration)
        {
            var client = new HttpClient();
            var response = await client.GetAsync("http://localhost:2912/api/subscriber/" + subscriberId.ToString());

            response.StatusCode.Should().Be(System.Net.HttpStatusCode.OK, "the response status code value should be “Ok”");
            var jsonResult = await response.Content.ReadAsStringAsync();
            var result = JObject.Parse(jsonResult);
            ((string)result["name"]).Should().Be(name, "that was the saved database name value");

            if (string.IsNullOrEmpty(expiration))
            {
                ((DateTime?)result["expiration"]).Should().BeNull("a null value was saved as the database expiration value");
            }
            else
            {
                DateTime? exp = (DateTime?)DateTime.Parse(expiration);
                ((DateTime?)result["expiration"]).Should().Be(exp, "that was the saved database expiration value");
            }
        }
    }
}
