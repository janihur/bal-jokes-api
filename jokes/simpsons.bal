import ballerina/http;
import ballerina/log;

configurable string SIMPSONS_URL = ?;

final http:Client simpsonsClient = check new http:Client(SIMPSONS_URL);

isolated function simpsons(int? amount) returns AllowedResponseType {
    // quotes
    // quotes?count=1
    http:Response|http:ClientError response = simpsonsClient->get(
        path = "quotes" + (amount is int ? string`?count=${amount}` : "")
    );

    if response is http:Response {
        log:printInfo("SIMPSONS http:Response", keyValues = responseToKeyValues(response));
        json|http:ClientError jsonPayload = response.getJsonPayload();
        if jsonPayload is json {
            return simpsonsConvert(jsonPayload);
        } else {
            log:printError("SIMPSONS http:ClientError", jsonPayload);
            return buildClientError(jsonPayload.toString());
        }
    } else {
        log:printError("SIMPSONS http:ClientError", response);
        return buildClientError(response.toString());
    }
}

isolated function simpsonsConvert(json simpsons) returns AllowedResponseType {
    json[] jokes = 
        from var quote in <json[]>simpsons 
        let string text = safeAccess(quote.quote) // TODO hides error scenarios
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