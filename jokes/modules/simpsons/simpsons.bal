import ballerina/http;
import ballerina/log;

import jokes.common as common;

configurable string SIMPSONS_URL = ?;

final http:Client simpsonsClient = check new http:Client(SIMPSONS_URL);

public isolated function quotes(int? amount = ()) returns common:AllowedResponseType {
    // quotes
    // quotes?count=1
    http:Response|http:ClientError response = callApi(
        path = "quotes" + (amount is int ? string`?count=${amount}` : "")
    );

    if response is http:Response {
        match response.statusCode {
            http:STATUS_OK => {
                log:printInfo("SIMPSONS http:Response", keyValues = common:responseToKeyValues(response));
                json|http:ClientError jsonPayload = response.getJsonPayload();
                if jsonPayload is json {
                    return simpsonsConvert(jsonPayload);
                } else {
                    log:printError("SIMPSONS http:ClientError", jsonPayload);
                    return common:buildClientError(jsonPayload.toString());
                }
            }
            _ => {
                log:printError("SIMPSONS http:Response", keyValues = common:responseToKeyValues(response));
                return common:buildClientError(common:responseToSexprStr(response));
            }
        }
    } else {
        log:printError("SIMPSONS http:ClientError", response);
        return common:buildClientError(response.toString());
    }
}

# `http:Client` call capsulated for own function for unit testing.
# + path - request path
# + return - whatever `http:Client` returns
isolated function callApi(string path) returns http:Response|http:ClientError {
    return simpsonsClient->get(path);
}

isolated function simpsonsConvert(json simpsons) returns common:AllowedResponseType {
    json[] jokes = 
        from var quote in <json[]>simpsons 
        let string text = common:safeAccess(quote.quote) // TODO hides error scenarios
        select {
            family: "simpsons",
            text: text
        }
    ;
    
    return <http:Ok> {
        body: <json> {
            jokes: jokes
        }
    };
}