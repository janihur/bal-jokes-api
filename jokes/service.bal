import ballerina/http;
import ballerina/log;
import ballerina/xmldata;

import jokes.chucknorris;
import jokes.common;
import jokes.simpsons;

service /jokes/v1 on new http:Listener(9090) {
    isolated resource function get 'json (string family, int? amount) 
    returns 
      http:Ok
    | http:BadRequest
    | http:InternalServerError
    {
        log:printInfo("json2 (GET)", family = family, amount = amount);

        common:AllowedResponseType response = impl(family, amount);

        log:printInfo("json2 (GET)", response = response.toString());
        return response;
    }

    isolated resource function get 'xml (string family, int? amount) 
    returns 
      http:Ok
    | http:BadRequest
    | http:InternalServerError
    {
        log:printInfo("xml (GET)", family = family, amount = amount);

        common:AllowedResponseType response = impl(family, amount);

        // convert JSON to XML
        do {
            if response is http:Ok {
                response.body = check convertJsonToXml(
                    check (<json>response?.body).jokes,
                    x => xml`<jokes>${x}</jokes>`,
                    { arrayEntryTag: "joke" }
                );
            } else {
                response.body = check convertJsonToXml(
                    <json>response?.body,
                    x => xml`<error>${x}</error>`
                );
            }
        } on fail error err {
            response = common:buildImplementationError(err.message());
        }

        log:printInfo("xml (GET)", response = response.toString());
        return response;
    }
}

//
// Wrapper that quarantees the underlying code doesn't leak errors
// but always returns valid return type.
//
isolated function impl(string family, int? amount) returns common:AllowedResponseType {
    common:AllowedResponseType|error response = trap impl_(family, amount);
    if response is error {
        return common:buildImplementationError(response.message());
    } else {
        return response;
    }
}

//
// Actual implementation.
//
type DataSourceFunction isolated function(int?) returns common:AllowedResponseType;

# Resolve actual data source function based on `family`.
# + family - the data family
# + return - data source function for `family`
isolated function getDataSourceFunction(string family) returns DataSourceFunction {
    var defaultDataSource = isolated function(int? amount) returns common:AllowedResponseType {
        return common:buildNotImplementedError();
    };
    match family {
        CHUCKNORRIS => { return chucknorris:facts; }
        IPSUM       => { return defaultDataSource; }
        SIMPSONS    => { return simpsons:quotes; }
        _           => { return defaultDataSource; } // never reached as value validated above
    }
}

isolated function impl_(string family, int? amount) returns common:AllowedResponseType {
    common:ValidationError? validationError = validate(family, amount);
    if validationError is common:ValidationError {
        return validationError;
    } else {
        DataSourceFunction dsf = getDataSourceFunction(family);
        return dsf(amount);
    }
}

//
// Validate all query parameters.
//
const string validFamilies = "'chucknorris', 'ipsum', 'simpsons'";

enum ValidFamily {
    CHUCKNORRIS = "chucknorris",
    IPSUM       = "ipsum",
    SIMPSONS    = "simpsons"
}

isolated function validate(string family, int? amount) returns common:ValidationError? {
    if family !is ValidFamily {
        return common:buildValidationError(string`Invalid family: '${family}'. Valid values: ${validFamilies}.`);
    }
    if amount is int && amount < 1 {
        return common:buildValidationError(string`Invalid amount: ${amount}. Valid values are positive integers greater than zero.`);
    }
    return;
}

isolated function convertJsonToXml(
    json 'json, 
    (isolated function (xml 'xml) returns xml)? wrapper = (),
    xmldata:JsonOptions jsonOptions = {}
) returns xml|error {
    xml? x1 = check xmldata:fromJson('json, jsonOptions);
    if x1 is xml {
        // rename top element from <root> to <response>
        // and wrap the content if needed
        xml x2 = x1/*;
        if wrapper !is () {
            return xml`<response>${wrapper(x2)}</response>`;    
        } else {
            return xml`<response>${x2}</response>`;
        }
    }
    return error("JSON to XML conversion failed.");
}
