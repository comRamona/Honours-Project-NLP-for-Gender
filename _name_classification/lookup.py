from nametools import process_str
from affiliations import affiliations
import os
import http.client, urllib.parse, json

#lookup person on Bing Search and return seult

search_subscription_key = 'cce29d93e6ce4e979eff46507d35b287'
uri_base = 'https://westeurope.api.cognitive.microsoft.com'  
host = "api.cognitive.microsoft.com"
path = "/bing/v7.0/images/search"

def BingImageSearch(search):
	"Performs a Bing image search and returns the results."
	try:

		headers = {'Ocp-Apim-Subscription-Key': search_subscription_key}
		conn = http.client.HTTPSConnection(host)
		query = urllib.parse.quote(search)
		conn.request("GET", path + "?q=" + query, headers=headers)
		response = conn.getresponse()
		headers = [k + ": " + v for (k, v) in response.getheaders()
		               if k.startswith("BingAPIs-") or k.startswith("X-MSEdge-")]
		headers, result = headers, response.read().decode("utf8")

		res = json.loads(result)
		value = res["value"]
		return value
	except Exception as e:
		print('Error:',search)
		print(e)
	# print("\nJSON Response:\n")
	# print(json.dumps(json.loads(result), indent=4))

	return None
