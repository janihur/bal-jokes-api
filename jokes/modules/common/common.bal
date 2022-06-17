import ballerina/http;
import ballerina/log;
import ballerina/mime;

//
// Application specific error types and error value builders
//
public type ClientError         http:InternalServerError;
public type ImplementationError http:InternalServerError;
public type NotImplementedError http:InternalServerError;
public type ValidationError     http:BadRequest;

public type AllowedResponseType http:Ok|ClientError|ImplementationError|NotImplementedError|ValidationError;

public isolated function buildClientError(string details) returns ClientError {
    return {
        body: buildErrorRecord("CLIENT", details)
    };
}

public isolated function buildImplementationError(string details) returns ImplementationError {
    return {
        body: buildErrorRecord("IMPLEMENTATION", details)
    };
}

public isolated function buildNotImplementedError() returns NotImplementedError {
    return {
        body: buildErrorRecord("NOT_IMPLEMENTED", "Unfortunately the implementation is not yet available. Please call back later.")
    };
}

public isolated function buildValidationError(string details) returns ValidationError {
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

# Convert Ballerina `error` to a sexpr-like string.
# The purpose is to use the string in error response `details`-field.
# + err - `error` to be converted
# + return - sexpr-like string representation of `error`
public isolated function errorToSexprStr(error err) returns string {
    string s = string`(error ((message "${err.message()}")`;

    // details (optional)
    do {
        var details = err.detail();
        var keys = details.keys();
        if keys.length() > 0 {
            s += "(details (";
            foreach var key in keys {
                s += string`(${key} `;
                any|error value = details.get(key); // value might be an error in general case but not here
                if value is error {
                    s += "error";
                } else if value is () {
                    s += "nil";
                } else if value is string {
                    s += string`"${value}"`;
                } else {
                    s += value.toString();
                }
                s += ")";
            }
            s += "))";
        }
    }

    // cause (optional)
    do {
        error? cause = err.cause();
        if cause is error {
            s += string`(cause ${errorToSexprStr(cause)})`;
        }
    }

    s += "))";
    return s;
}

//
// guarantees json value is converted to a string
// drawback: possible errors are hidden
// 
public isolated function safeAccess(json|error val) returns string {
    if val is json {
        return <string>val;
    } else {
        return "";
    }
}

# Convert Ballerina `http:Response` to a sexpr-like string.
# The purpose is to use the string in error response `details`-field.
# Note only subset of information is returned.
# + r - `http:Response` to be converted
# + return - sexpr-like string representation of `http:Response`
public isolated function responseToSexprStr(http:Response r) returns string {
    log:KeyValues kv = responseToKeyValues(r);
    string httpStatusCode = kv.get("statusCode").toString();
    string body = kv.get("entity.body").toString();
    string s = string`(http:Response ((http_status_code ${httpStatusCode})(body "${body}")))`;
    return s;
}

// TODO expand to the more details
public isolated function responseToKeyValues(http:Response r) returns log:KeyValues {
    log:KeyValues keyValues = {
        "statusCode": r.statusCode,
        "reasonPhase": r.reasonPhrase,
        "contentType": r.getContentType(),
        "resolvedRequestedURI": r.resolvedRequestedURI,
        "server": r.server
    };

    mime:Entity|http:ClientError entity = r.getEntity();
    if entity is mime:Entity {
        keyValues["entity.ContentType"] = entity.getContentType();
    
        foreach string headerName in entity.getHeaderNames() {
            string computedHeaderName = "header." + headerName;
            string|mime:HeaderNotFoundError headerValue = entity.getHeader(headerName);
            if headerValue is string {
                keyValues[computedHeaderName] = headerValue;
            } else {
                keyValues[computedHeaderName] = headerValue.message();
            }
        }

        if entity.getContentType().startsWith("application/json") {
            json|mime:ParserError body = entity.getJson();
            if body is json {
                keyValues["entity.body"] = body.toString();
            } else {
                keyValues["entity.body"] = body.toString();
            }
        } else if entity.getContentType().startsWith("text/xml") {
            xml|mime:ParserError body = entity.getXml();
            if body is xml {
                keyValues["entity.body"] = body.toString();
            } else {
                keyValues["entity.body"] = body.toString();
            }
        } else if entity.getContentType().startsWith("text/html") {
            string|mime:ParserError body = entity.getText();
            if body is string {
                keyValues["entity.body"] = body;
            } else {
                keyValues["entity.body"] = body.toString();
            }
        } else { // treat as text
            string|mime:ParserError body = entity.getText();
            if body is string {
                keyValues["entity.body"] = body;
            } else {
                keyValues["entity.body"] = body.toString();
            }
        }
    }

    return keyValues;
}
