#!/usr/bin/env python
"""Wordnik.com's Swagger generic API client. This client handles the client-
server communication, and is invariant across implementations. Specifics of
the methods and models for each application are generated from the Swagger
templates."""

import sys
import os
import re
import urllib
import urllib2
import MultipartPostHandler
import json
import datetime
import keyword
import base64

from models import *


class ApiClient(object):
    """Generic API client for Swagger client library builds"""

    def __init__(self, api_server='https://api.namsor.com/onomastics/api/json'):
        self.api_server = api_server
        self.cookie = None
        # authentication
        self.api_key = ''
        self.api_key_type = ''
        self.api_key_name = ''
        self.api_key_prefix = ''
        self.username = ''
        self.password = ''

    def __parse_string_to_datetime(self, value):
        """ convert string to datetime """ 
        from dateutil.parser import parse

        if not value:
            return None
        return parse(value)

    def __authentication(self):
        headers, query_params = {}, {}

        # authenticatio with api key in header 
        if self.api_key_type == 'header':
            if self.api_key_prefix:
                headers[self.api_key_name] = "%s %s" % (self.api_key_prefix, self.api_key)
            else:
                headers[self.api_key_name] = self.api_key
        elif self.api_key_type == 'query': # authentication with URL query parameter
            query_params[self.api_key_name] = self.api_key
        else: # http basic auth
            if self.username and self.password:
                headers['Authorization'] = self.__http_auth_header()

        return (headers, query_params)

    def __http_auth_header(self):
        return 'Basic %s' % base64.encodestring('%s:%s' % (self.username, self.password)).replace('\n', '')

    def callAPI(self, resourcePath, method, queryParams, postData,
                headerParams=None, requireAuth=False):

        url = self.api_server + resourcePath

        # authentication
        _auth_headers, _auth_query_params = {}, {}
        if requireAuth:
            _auth_headers, _auth_query_params = self.__authentication()
        headerParams = headerParams if headerParams else {}
        queryParams = queryParams if queryParams else {}
        headerParams.update(_auth_headers)
        queryParams.update(_auth_query_params)

        headers = {}
        if headerParams:
            for param, value in headerParams.iteritems():
                headers[param] = value
       
        # user agent
        headers['User-Agent'] = 'Swagger/Python/0.21.1/prod'

        if self.cookie:
            headers['Cookie'] = self.cookie

        data = None

        if queryParams:
            # Need to remove None values, these should not be sent
            sentQueryParams = {}
            for param, value in queryParams.items():
                if value is not None:
                    sentQueryParams[param] = value
            url = url + '?' + urllib.urlencode(sentQueryParams)

        if method in ['GET']:

            #Options to add statements later on and for compatibility
            pass

        elif method in ['POST', 'PUT', 'PATCH', 'DELETE']:

            if postData:
                data = self.sanitizeForSerialization(postData)
                headers, data = self.preparePostRequest(headers, data)

        else:
            raise Exception('Method ' + method + ' is not recognized.')

        request = MethodRequest(method=method, url=url, headers=headers,
                                data=data)

        # Make the request
        response = urllib2.urlopen(request)
        if 'Set-Cookie' in response.headers:
            self.cookie = response.headers['Set-Cookie']
        string = response.read()

        try:
            data = json.loads(string)
        except ValueError:  # PUT requests don't return anything
            data = string

        return data

    def toPathValue(self, obj):
        """Convert a string or object to a path-friendly value
        Args:
            obj -- object or string value
        Returns:
            string -- quoted value
        """
        if type(obj) == list:
            return urllib.quote(','.join(obj))
        else:
            return urllib.quote(str(obj))

    def sanitizeForSerialization(self, obj):
        """Dump an object into JSON for POSTing."""

        if isinstance(obj, type(None)):
            return None
        elif isinstance(obj, (str, int, long, float, bool, file)):
            return obj
        elif isinstance(obj, list):
            return [self.sanitizeForSerialization(subObj) for subObj in obj]
        elif isinstance(obj, datetime.datetime):
            return obj.isoformat()
        else:
            if isinstance(obj, dict):
                objDict = obj
            else:
                objDict = obj.__dict__
            return {
                self.__sanitizeKey(key, obj): self.sanitizeForSerialization(val)
                for (key, val) in objDict.iteritems()
                if key != 'swaggerTypes' and key != 'attributeMap' and val is not None
            }

    def preparePostRequest(self, headers, data):
        """ Serialize data for POST request body """
        if 'Content-Type' not in headers:
            headers['Content-Type'] = 'application/json'
            data = json.dumps(data)
        elif headers['Content-Type'] == 'application/json':
            data = json.dumps(data)
        elif headers['Content-Type'] == 'multipart/form-data':
            opener = urllib2.build_opener(MultipartPostHandler.MultipartPostHandler)
            urllib2.install_opener(opener)
        elif headers['Content-Type'] == 'application/x-www-form-urlencoded':
            data = urllib.urlencode(data)
        else:
            data = urllib.urlencode(data)
        return (headers, data)


    def __sanitizeKey(self, key, obj):
        """
        Serialize dict key to json key
        """
        try:
            return obj.attributeMap[key]
        except AttributeError:
            return obj



    def deserialize(self, obj, objClass):
        """Derialize a JSON string into an object.

        Args:
            obj -- string or object to be deserialized
            objClass -- class literal for deserialzied object, or string
                of class name
        Returns:
            object -- deserialized object"""

        # Have to accept objClass as string or actual type. Type could be a
        # native Python type, or one of the model classes.
        if type(objClass) == str:
            if 'list[' in objClass:
                match = re.match('list\[(.*)\]', objClass)
                subClass = match.group(1)
                return [self.deserialize(subObj, subClass) for subObj in obj]

            if objClass in ['int', 'float', 'long', 'dict', 'list', 'str', 'bool', 'datetime']:
                objClass = eval(objClass)
            else:  # not a native type, must be model class
                objClass = eval(objClass + '.' + objClass)

        if objClass in [int, long, float, dict, list, str, bool]:
            return objClass(obj)
        elif objClass == datetime:
            return self.__parse_string_to_datetime(obj)

        instance = objClass()

        for attr, attrType in instance.swaggerTypes.iteritems():
            key = self.__sanitizeKey(attr, instance)
            if obj is not None and key in obj and type(obj) in [list, dict]:
                value = obj[key]
                if attrType in ['str', 'int', 'long', 'float', 'bool']:
                    attrType = eval(attrType)
                    try:
                        value = attrType(value)
                    except UnicodeEncodeError:
                        value = unicode(value)
                    except TypeError:
                        value = value
                    setattr(instance, attr, value)
                elif (attrType == 'datetime'):
                    datetime_value = self.__parse_string_to_datetime(value)
                    setattr(instance, attr, datetime_value)
                elif 'list[' in attrType:
                    match = re.match('list\[(.*)\]', attrType)
                    subClass = match.group(1)
                    subValues = []
                    if not value:
                        setattr(instance, attr, None)
                    else:
                        for subValue in value:
                            subValues.append(self.deserialize(subValue,
                                                              subClass))
                    setattr(instance, attr, subValues)
                else:
                    setattr(instance, attr, self.deserialize(value,
                                                             attrType))

        return instance


class MethodRequest(urllib2.Request):

    def __init__(self, *args, **kwargs):
        """Construct a MethodRequest. Usage is the same as for
        `urllib2.Request` except it also takes an optional `method`
        keyword argument. If supplied, `method` will be used instead of
        the default."""

        if 'method' in kwargs:
            self.method = kwargs.pop('method')
        return urllib2.Request.__init__(self, *args, **kwargs)

    def get_method(self):
        return getattr(self, 'method', urllib2.Request.get_method(self))


