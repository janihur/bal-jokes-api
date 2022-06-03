import ballerina/http;
import ballerina/log;
import ballerina/xmldata;

service /jokes/v1 on new http:Listener(9090) {
    isolated resource function get 'json (string family, int? amount) 
    returns 
      http:Ok
    | http:BadRequest
    | http:InternalServerError
    {
        log:printInfo("json2 (GET)", family = family, amount = amount);

        AllowedResponseType response = impl(family, amount);

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

        AllowedResponseType response = impl(family, amount);
        // TODO conversion functions can be refactored
        if response is http:Ok {
            response.body = convertJsonToXml(<json>response?.body);
        } else {
            response.body = convertJsonErrorToXmlError(<json>response?.body);
        }

        log:printInfo("xml (GET)", response = response.toString());
        return response;
    }
}

//
// Wrapper that quarantees the underlying code doesn't leak errors
// but always returns valid return type.
//
isolated function impl(string family, int? amount) returns AllowedResponseType {
    AllowedResponseType|error response = trap impl_(family, amount);
    if response is error {
        return buildImplementationError(response.message());
    } else {
        return response;
    }
}

//
// Actual implementation.
//
isolated function impl_(string family, int? amount) returns AllowedResponseType {
    ValidationError? validationError = validate(family, amount);
    if validationError is ValidationError {
        return validationError;
    } else {
        match family {
            CHUCKNORRIS => { return chucknorris(amount); }
            IPSUM       => { return buildNotImplementedError(); }
            SIMPSONS    => { return simpsons(amount); }
            _           => { return buildNotImplementedError(); } // never reached as value validated above
        }
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

isolated function validate(string family, int? amount) returns ValidationError? {
    if family !is ValidFamily {
        return buildValidationError(string`Invalid family: '${family}'. Valid values: ${validFamilies}.`);
    }
    if amount is int && amount < 1 {
        return buildValidationError(string`Invalid amount: ${amount}. Valid values are positive integers greater than zero.`);
    }
    return;
}

//
// Convert JSON structure to XML structure
//
isolated function convertJsonToXml(json? 'json) returns xml? {
    if 'json is () {
        return;
    }
    // xmlData module has hard-coded root element name :(
    xml?|xmldata:Error x1 = xmldata:fromJson(checkpanic 'json.jokes, { arrayEntryTag: "joke" });
    if x1 is xml {
        // rename root element(s)
        xml x2 = x1/*;
        return xml`<response><jokes>${x2}</jokes></response>`;
    }
    return; // TODO xmldata:Error is ignored
}

//
// Convert JSON error structure to XML error structure.
//
isolated function convertJsonErrorToXmlError(json? 'json) returns xml? {
    if 'json is () {
        return;
    }
    // xmlData module has hard-coded root element name :(
    xml?|xmldata:Error x1 = xmldata:fromJson('json);
    if x1 is xml {
        // rename root element(s)
        xml x2 = x1/*;
        return xml`<response><error>${x2}</error></response>`;
    }
    return; // TODO xmldata:Error is ignored
}

//
// Application specific error types and error value builders
//
type ClientError         http:InternalServerError;
type ImplementationError http:InternalServerError;
type NotImplementedError http:InternalServerError;
type ValidationError     http:BadRequest;

type AllowedResponseType http:Ok|ClientError|ImplementationError|NotImplementedError|ValidationError;

isolated function buildClientError(string details) returns ClientError {
    return {
        body: buildErrorRecord("CLIENT", details)
    };
}

isolated function buildImplementationError(string details) returns ImplementationError {
    return {
        body: buildErrorRecord("IMPLEMENTATION", details)
    };
}

isolated function buildNotImplementedError() returns NotImplementedError {
    return {
        body: buildErrorRecord("NOT_IMPLEMENTED", "Unfortunately the implementation is not yet available. Please call back later.")
    };
}

isolated function buildValidationError(string details) returns ValidationError {
    return {
        body: buildErrorRecord("VALIDATION", details)
    };
}

isolated function buildErrorRecord(string code, string details) returns json {
    return {
        code: code,
        details: details
    };
}