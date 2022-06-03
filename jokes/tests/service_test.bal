import ballerina/test;

@test:Config {}
function convertJsonToXmlTest1() {
    final json input = {
        jokes: [
            {
                family: "family 1",
                text: "text 1"
            },
            {
                family: "family 2",
                text: "text 2"
            }
        ]
    };
    xml expected = xml`<jokes><joke><family>family 1</family><text>text 1</text></joke><joke><family>family 2</family><text>text 2</text></joke></jokes>`;
    xml? got = convertJsonToXml(input);
    test:assertEquals(got, expected);
}
