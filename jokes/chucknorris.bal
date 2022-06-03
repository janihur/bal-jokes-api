import ballerina/http;
import ballerina/log;

configurable string CHUCKNORRIS_URL = ?;

final http:Client chucknorrisClient = check new http:Client(CHUCKNORRIS_URL);

isolated function chucknorris(int? amount) returns AllowedResponseType {
    (http:Response|http:ClientError)[] responses = chucknorrisCall(amount is int ? amount : 1);

    // all calls are required to success
    // iterative example
    {
        // (http:Response|http:ClientError)[] failed = responses.filter(isolated function(http:Response|http:ClientError item) returns boolean {
        //     return item is http:ClientError;
        // });

        [int, http:ClientError][] failed = [];
        foreach var item in responses.enumerate() {
            var index = item[0];
            var response = item[1];
            if response is http:ClientError {
                failed.push([index, response]);
            }
        }

        // could be done in the for-loop above too
        string failureStr = failed.reduce(isolated function (string accu, [int,http:ClientError] item) returns string {
            var index = item[0];
            var err = item[1];
            return string`${accu};(failure ((call_index ${index})(error ${err.toString()}))`;
        }, "");

        if failureStr.length() > 0 {
            return buildClientError(failureStr);
        }
    }

    // all calls succeeded
    // convert from http:Response to json

    // (http:Response|http:ClientError)[] successed = responses.filter(isolated function(http:Response|http:ClientError item) returns boolean {
    //     return item is http:Response;
    // });

    // getting the type without error is not possible in any other way
    http:Response[] successed = [];
    foreach var item in responses {
        if item is http:Response {
            successed.push(item);
        }
    }

    (json|http:ClientError)[] jsonPayloads = successed.map(isolated function (http:Response item) returns json|http:ClientError {
        return item.getJsonPayload();
    });

    // all conversions are required to success
    // functional example - can't get rid of error component in the types this way
    {
        (json|http:ClientError)[] failed = jsonPayloads.filter(isolated function (json|http:ClientError item) returns boolean {
            return item is http:ClientError;
        });

        string failureStr = failed.reduce(isolated function (string accu, json|http:ClientError err) returns string {
            if err is http:ClientError {
                return string`${accu};${err.toString()}`;
            }
            return accu;
        }, "");

        if failureStr.length() > 0 {
            return buildClientError(failureStr);
        }
    }

    // all conversions succeeded
    // construct the success return value

    json[] jokes = jsonPayloads.map(isolated function(json|http:ClientError item) returns json {
        if item is json {
            return {
                family: "chucknorris",
                text: safeAccess(item.value)
            };
        }
        return {};
    });

    return <http:Ok> {
        body: <json> {
            jokes: jokes
        }
    };
}

isolated function chucknorrisCall(int amount) returns (http:Response|http:ClientError)[] {
    (http:Response|http:ClientError)[] responses = [];
    foreach int i in 1...amount {
        http:Response|http:ClientError response = chucknorrisClient->get(
            path = "random"
        );
        responses.push(response);
        if response is http:Response {
            log:printInfo("CHUCKNORRIS http:Response", keyValues = responseToKeyValues(response));
        } else {
            log:printError("CHUCKNORRIS http:ClientError", response);
        }
    }
    return responses;
}