import ballerina/http;
import ballerina/test;

import jokes.common;

@test:Mock { functionName: "callApi" }
test:MockFunction callApiMockFn = new();

// it's not possible to mock final variables so we can't:
// chucknorrisClient = test:mock(http:Client)
@test:Config{}
function test_facts_nocontent() returns error? {
    http:Response mockRes = new;

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = facts();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("NoContentError"));
}

@test:Config{}
function test_facts_notfound() returns error? {
    http:Response mockRes = new;
    mockRes.statusCode = http:STATUS_NOT_FOUND;
    mockRes.setJsonPayload({"timestamp":"2022-06-12T09:26:21.294Z","status":404,"error":"Not Found","message":"Joke with id \"randomxxx\" not found.","path":"/jokes/randomxxx"});

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = facts();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("(http_status_code 404)"));
}

@test:Config{}
function test_facts_clienterror() returns error? {
    http:ClientError mockRes = error("HTTP_CLIENT_ERROR");

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = facts();

    test:assertTrue(r is common:ClientError);

    string details = check (<json>r?.body).details;

    test:assertTrue(details.includes("ClientError"));
}

@test:Config{}
function test_facts_ok() {
    http:Response mockRes = new;
    mockRes.setJsonPayload({"categories":[],"created_at":"2020-01-05 13:42:20.568859","icon_url":"https://assets.chucknorris.host/img/avatar/chuck-norris.png","id":"CARdiEISR9CaJa5CAIxy7g","updated_at":"2020-01-05 13:42:20.568859","url":"https://api.chucknorris.io/jokes/CARdiEISR9CaJa5CAIxy7g","value":"they say Santa comes once a yer Chuck Norris comes twice a year"});

    test:when(callApiMockFn).thenReturn(mockRes);

    common:AllowedResponseType r = facts();

    test:assertTrue(r is http:Ok);

    json expected = {"jokes":[{"family":"chucknorris","text":"they say Santa comes once a yer Chuck Norris comes twice a year"}]};
    json got = <json>r?.body;

    test:assertEquals(got, expected);
}