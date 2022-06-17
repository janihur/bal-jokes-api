# bal-jokes-api
An example Ballerina Swan Lake project that provides an unified API to call different humorous APIs to highlight some Ballerina features.

The humorous APIs are:

* https://api.chucknorris.io
* https://baconipsum.com/json-api/
* https://thesimpsonsquoteapi.glitch.me

## Tentative TODO-list
Potential enhancements in no particular order:

* https://ballerina.io/learn/test-ballerina-code/
  * data providers
  * mock functions
* Ballerina `error` conversion to application specific JSON error structure
  * enable error chaining and listing multiple errors
* https://ballerina.io/learn/by-example/http-interceptors.html
* Concurrency
* https://ballerina.io/learn/cli-documentation/openapi/
* https://ballerina.io/learn/by-example/cache-basics.html
* https://ballerina.io/learn/generate-code-documentation/#write-ballerina-documentation


## Ballerina commands
Modules have configration so all commands require:
```
export BAL_CONFIG_FILES='Config.toml:modules/chucknorris/Config.toml:modules/simpsons/Config.toml'
```

Run unit tests:
```
bal test --test-report --code-coverage
```

## How to call the API
### Using query parameters
Supported query parameters:
* Mandatory: `family` - valid values: `chucknorris`, `ipsum`, `simpsons`
* Optional: `amount` - integer greater than zero, defaults to 1.

Examples:
```
# get two simpsons jokes in json
curl -v 'http:/localhost:9090/jokes/v1/json?family=simpsons&amount=2'
# get two simpsons jokes in xml
curl -v 'http:/localhost:9090/jokes/v1/xml?family=simpsons&amount=2'
```

### Using JSON payload
TODO

* `amount` is optional. Default value is 1.
* The same family can be listed any number of times and the total sum is calculated.

Example:
```
{
  "requests": [
    {
      "family": "chucknorris",
      "amount": 2
    },
    {
      "family": "simpsons"
    }
  ]
}
```

### Using XML payload
TODO

## Success responses
HTTP status code 200 Ok
```
{
  "jokes": [
    {
      "family": "simpsons",
      "text": "Shoplifting is a victimless crime, like punching someone in the dark."
    },
    {
      "family": "simpsons",
      "text": "Eat my shorts"
    }
  ]
}
```
```
<response>
  <jokes>
    <joke>
      <family>simpsons</family>
      <text>Shoplifting is a victimless crime, like punching someone in the dark.</text>
    </joke>
    <joke>
      <family>simpsons</family>
      <text>Eat my shorts</text>
    </joke>
  </jokes>
</response>
```

## Error responses
This version returns only HTTP status codes:
* 400 Bad Request
* 500 Internal Server Error

Error payload examples:
```
{
    "code":"NOT_IMPLEMENTED", 
    "details":"Unfortunately the implementation is not yet available. Please call back later."
}
```
```
<response>
  <error>
    <code>NOT_IMPLEMENTED</code>
    <details>Unfortunately the implementation is not yet available. Please call back later.</details>
  </error>
</response>
```
## Using Chuck Norris API
```
curl -v https://api.chucknorris.io/jokes/random
```
```
{"categories":[],"created_at":"2020-01-05 13:42:29.569033","icon_url":"https://assets.chucknorris.host/img/avatar/chuck-norris.png","id":"Ma0dcm41QLyJVOlz7f896w","updated_at":"2020-01-05 13:42:29.569033","url":"https://api.chucknorris.io/jokes/Ma0dcm41QLyJVOlz7f896w","value":"Miley Cyrus calls Chuck Norris daddy."}
```

## Using Bacon Ipsum API
```
curl -v 'https://baconipsum.com/api/?type=meat-and-filler&sentences=1&start-with-lorem=1'
```
```
["Bacon ipsum dolor amet short ribs fatback cow proident, pork loin corned beef voluptate occaecat dolor tenderloin do nostrud sint biltong anim."]
```

## Using Simpsons API
```
curl -v https://thesimpsonsquoteapi.glitch.me/quotes
curl -v https://thesimpsonsquoteapi.glitch.me/quotes?count=2
```
```
[{"quote":"Shoplifting is a victimless crime, like punching someone in the dark.","character":"Nelson Muntz","image":"https://cdn.glitch.com/3c3ffadc-3406-4440-bb95-d40ec8fcde72%2FNelsonMuntz.png?1497567511185","characterDirection":"Left"},{"quote":"Eat my shorts","character":"Bart Simpson","image":"https://cdn.glitch.com/3c3ffadc-3406-4440-bb95-d40ec8fcde72%2FBartSimpson.png?1497567511638","characterDirection":"Right"}]
```
