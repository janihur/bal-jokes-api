import ballerina/http;
import ballerina/log;
import ballerina/mime;

//
// guarantees json value is converted to a string
// drawback: possible errors are hidden
// 
isolated function safeAccess(json|error val) returns string {
    if val is json {
        return <string>val;
    } else {
        return "";
    }
}

// TODO expand to the more details
isolated function responseToKeyValues(http:Response r) returns log:KeyValues {
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

        if entity.getContentType().startsWith("text/xml;") {
            xml|mime:ParserError body = entity.getXml();
            if body is xml {
                keyValues["entity.body"] = body.toString();
            } else {
                keyValues["entity.body"] = body.toString();
            }
        }

        if entity.getContentType().startsWith("application/json;") {
            json|mime:ParserError body = entity.getJson();
            if body is json {
                keyValues["entity.body"] = body.toString();
            } else {
                keyValues["entity.body"] = body.toString();
            }
        }
        // TODO other entity types
    }

    return keyValues;
}