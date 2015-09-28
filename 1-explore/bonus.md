## Advanced Exploration-Related Hacks 

If we wanted to see tye type of each of the items inside Reservations, we could
create a new object that describes them. One that looks like this: 

```{
  "Groups": "string",
  "Instances": "string",
  "OwnerId": "array",
  "ReservationId": "array"
}
```

There are two ways to do this that I can think of: The first solution creates
two arrays, one of keys and one of types. Then it saves them both as variables,
and uses the size of the keys array (.[0] piped to range(length)) to iterively
build a new object with variable references.

``` 
jq '.[][0]|[keys,[(.[]|type)]] | . as [$k,$v] | .[0] |[range(length)|{($k[.]):($v[.])}] | add' in.json 
```

This solution starts the same way, but rather than using variables, it
transposes the keys and types arrays together, and then uses map to build the
object with array indices. 

```
jq '.[][0]|[keys,[(.[]|type)]] | transpose |map( {(.[0]): (.[1])} ) |add' in.json
```
