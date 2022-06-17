import ballerina/http;
import ballerina/test;

//                    👇     👇
// extra tuple around [error] is a workaround for a bug 🤦
//                                              👇     👇
function errorToSexprStrTestData() returns map<[[error], string]> {
    return {
        messageOnly: [
            [error("messageOnly")],
            string`(error ((message "messageOnly")))`
        ],
        details: [
            [error("details", foo = 42, bar = "foobar")],
            string`(error ((message "details")(details ((foo 42)(bar "foobar")))))`
        ]
    };
}

@test:Config { dataProvider: errorToSexprStrTestData }
function errorToSexprStrTest([error]input, string expected) {
    final string got = errorToSexprStr(input[0]);
    test:assertEquals(got, expected);
}

@test:Config {}
function responseToSexprStrTest() returns error? {
    final http:Response input = new;
    input.statusCode = 404;
    check input.setContentType("text/html; charset=utf-8");
    input.setTextPayload(string`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Cannot GET /quotesxxx</pre>
</body>
</html>`);

    final string expected = string`(http:Response ((http_status_code 404)(body "<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Error</title>
</head>
<body>
<pre>Cannot GET /quotesxxx</pre>
</body>
</html>")))`;
    final string got = responseToSexprStr(input);
    test:assertEquals(got, expected);
}