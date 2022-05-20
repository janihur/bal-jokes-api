# bal-jokes-api
An example Ballerina Swan Lake project that provides an unified API to call two different humorous APIs to highlight some Ballerina features.

The humorous APIs are:

* https://thesimpsonsquoteapi.glitch.me
* https://api.chucknorris.io

The highligted Ballerina features:

* TODO

## How to call the API
```
# get two simpsons jokes in json
curl -v 'http:/localhost:9090/jokes/v1/json?family=simpsons&amount=2'
# get two simpsons jokes in xml
curl -v 'http:/localhost:9090/jokes/v1/xml?family=simpsons&amount=2'
```

## Error responses
This version returns only 
* 400 Bad Request
* 500 Internal Server Error

Error payload examples:
```
{"code":"NOT_IMPLEMENTED", "details":"Unfortunately the implementation is not yet available. Please call back later."}
```
```
<response>
  <error>
    <code>NOT_IMPLEMENTED</code>
    <details>Unfortunately the implementation is not yet available. Please call back later.</details>
  </error>
</response>
```
