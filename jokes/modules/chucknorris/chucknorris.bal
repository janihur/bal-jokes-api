import ballerina/http;
import ballerina/log;

import jokes.common as common;

configurable string CHUCKNORRIS_URL = ?;

final http:Client chucknorrisClient;

function init() returns error? {
    chucknorrisClient = check new http:Client(CHUCKNORRIS_URL);
}

public isolated function facts(int? amount = ()) returns common:AllowedResponseType {
    // ------------------------------------------------------------------------
    // 1) call the api
    //
    // quit if any call failed (but we'd like to do all the calls)
    // ------------------------------------------------------------------------
    http:Response[] responseOks = [];
    do {
        http:Response[] responseErrors = [];
        http:ClientError[] clientErrors = [];
        [responseOks, responseErrors, clientErrors] = chucknorrisCall(amount is int ? amount : 1);

        do {
            string failureStr = responseErrors.reduce(isolated function (string accu, http:Response res) returns string {
                return string`${accu}(failure ${common:responseToSexprStr(res)})`;
            }, "");

            if failureStr.length() > 0 {
                return common:buildClientError(failureStr);
            }
        }        

        do {
            string failureStr = clientErrors.reduce(isolated function (string accu, http:ClientError err) returns string {
                return string`${accu}(failure (error ${err.toString()}))`;
            }, "");

            if failureStr.length() > 0 {
                return common:buildClientError(failureStr);
            }
        }
    }

    // ------------------------------------------------------------------------
    // 2) convert from http:Response to json
    //
    // quit if any conversion failed (but we'd like to do all the conversions)
    // ------------------------------------------------------------------------
    json[] payloads = [];
    do {
        http:ClientError[] errors = [];
        foreach http:Response response in responseOks {
            json|http:ClientError payload = response.getJsonPayload();
            if payload is error {
                errors.push(payload);
            } else {
                payloads.push(payload);
            }
        }

        string failureStr = errors.reduce(isolated function (string accu, http:ClientError err) returns string {
            return string`${accu}(failure (error ${err.toString()}))`;
        }, "");

        if failureStr.length() > 0 {
            return common:buildClientError(failureStr);
        }
    }

    // ------------------------------------------------------------------------
    // 3) construct the success return value
    // ------------------------------------------------------------------------
    do {
        json[] jokes = payloads.map(isolated function(json item) returns json {
            return {
                family: "chucknorris",
                text: common:safeAccess(item.value) // TODO hides error scenarios
            };
        });

        return <http:Ok> {
            body: <json> {
                jokes: jokes
            }
        };
    }
}

isolated function chucknorrisCall(int amount) returns [http:Response[], http:Response[], http:ClientError[]] {
    http:Response[] responseOks = [];
    http:Response[] responseErrors = [];
    http:ClientError[] clientErrors = [];
 
    foreach int i in 1...amount {
        http:Response|http:ClientError response = callApi();
        if response is http:Response {
            match response.statusCode {
                http:STATUS_OK => {
                    log:printInfo("CHUCKNORRIS http:Response", keyValues = common:responseToKeyValues(response));
                    responseOks.push(response);
                }
                _ => {
                    log:printError("CHUCKNORRIS http:Response", keyValues = common:responseToKeyValues(response));
                    responseErrors.push(response);
                }
            }
        } else {
            log:printError("CHUCKNORRIS http:ClientError", response);
            clientErrors.push(response);
        }
    }

    return [responseOks, responseErrors, clientErrors];
}

# `http:Client` call capsulated for own function for unit testing.
# + return - whatever `http:Client` returns
isolated function callApi() returns http:Response|http:ClientError {
    return chucknorrisClient->get(path = "random");
}
