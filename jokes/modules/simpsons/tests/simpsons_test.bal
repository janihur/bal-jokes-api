import ballerina/http;
import ballerina/test;

import jokes.common;

@test:Mock { functionName: "callApi" }
test:MockFunction callApiMockFn = new();

@test:Config{}
function test_quotes_nocontent() returns error? {
    http:Response mockRes = new;

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = quotes();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("NoContentError"));
}

@test:Config{}
function test_quotes_notfound() returns error? {
    http:Response mockRes = new;
    mockRes.statusCode = http:STATUS_NOT_FOUND;
    mockRes.setTextPayload(string`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Cannot GET /quotesxxx</pre>
</body>
</html>`, "text/html; charset=utf-8");

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = quotes();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("(http_status_code 404)"));
}

@test:Config{}
function test_quotes_clienterror() returns error? {
    http:ClientError mockRes = error("HTTP_CLIENT_ERROR");

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = quotes();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("ClientError"));
}

@test:Config{}
function test_quotes_ok() {
    http:Response mockRes = new;
    mockRes.setJsonPayload([{"quote":"Eat my shorts","character":"Bart Simpson","image":"https://cdn.glitch.com/3c3ffadc-3406-4440-bb95-d40ec8fcde72%2FBartSimpson.png?1497567511638","characterDirection":"Right"}]);

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = quotes();

    test:assertTrue(r is http:Ok);

    json expected = {"jokes":[{"family":"simpsons","text":"Eat my shorts"}]};
    json got = <json>r?.body;

    test:assertEquals(got, expected);
}