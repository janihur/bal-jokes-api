import ballerina/http;
import ballerina/xmldata;
import ballerina/log;

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
        if response is http:Ok {
            // TODO convert to XML
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
    ValidationError? isValidationError = validate(family, amount);
    if isValidationError is ValidationError {
        return isValidationError;
    } else {
        // TODO the actual implementation will be called here
        // now just reporting not implemented
        return buildNotImplementedError();
    }
}

//
// Validate all query parameters.
//
isolated function validate(string family, int? amount) returns ValidationError? {
    match family {
        "chucknorris" | "simpsons" => {} // valid white-listed values
        _ => { 
            return buildValidationError(string`Invalid family: '${family}'. Valid values: 'chucknorris', 'simpsons'.`);
        }
    }
    if amount is int && amount < 1 {
        return buildValidationError(string`Invalid amount: ${amount}. Valid values are positive integers greater than zero.`);
    }
    return;
}

//
// Convert JSON error structure to XML error structure.
//
isolated function convertJsonErrorToXmlError(json? 'json) returns xml? {
    // missing ability to define root element name, now hard-coded to <root>
    xml?|xmldata:Error 'xml = xmldata:fromJson('json);
    // TODO xmldata:Error is hidden
    return 'xml is xml ? 'xml : ();
}

//
// Application specific error types and error value builders
//
type ImplementationError http:InternalServerError;
type NotImplementedError http:InternalServerError;
type ValidationError     http:BadRequest;

type AllowedResponseType http:Ok|ImplementationError|NotImplementedError|ValidationError;

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