from _name_classification.nametools import process_str
# Request headers.
########### Python 3.6 #############
import http.client, urllib.request, urllib.parse, urllib.error, base64, requests, json
import os
import re
##############################################
### Update or verify the following values. ###
##############################################


subscription_key = 'f50d898b2fad4edd8744c9aeae2a2738'
uri_base = 'https://westeurope.api.cognitive.microsoft.com'  

# Request headers.
headers = {
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': subscription_key,
}

# Request parameters.
params = {
    'returnFaceId': 'true',
    'returnFaceLandmarks': 'false',
    'returnFaceAttributes': 'gender',
}

def BingFaceDetection(url):


	# Body. The URL of a JPEG image to analyze.
	body = {'url': url}

	try:
	# Execute the REST API call and get the response.
		response = requests.request('POST', uri_base + '/face/v1.0/detect', json=body, data=None, headers=headers, params=params)

	
		parsed = json.loads(response.text)
	

	except Exception as e:
		print('Error:')
		print(e)
		return 0,parsed

	try:
		gender = parsed[0]["faceAttributes"]["gender"]
		return 1,gender
	except:
		return 0, parsed

	####################################    
