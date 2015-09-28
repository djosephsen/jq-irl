# The basics

`.` is *the input*. Here, try this: 

```
echo '[][]' | jq '.'
```

See? Dot *is* the current input, except as you can see, jq reformats it for you.
So if you have a huge blob of json like the blob inside [in.json](in.json), and
you run it through jq, and ask for it back using `.`, you'll get a nicely
formatted version.

``` 
jq '.' in.json 
```

`.[]` is whatever's *inside* the input. Here try this: 

```
echo '["foo"]' | jq .[]
```

See? Those brackets basically *unwrap* the top layer of the input. You can add
more to unwrap more layers: 

```
echo '[["foo"]]' | jq .[][]
```

All of this works, even if there's more than one top layer thingie in the
input: 

```
echo '["foo"]["bar"]' | jq '.'
echo '["foo"]["bar"]' | jq '.[]'
echo '[["foo"],["bar"]]' | jq '.[]'
echo '[["foo"],["bar"]]' | jq '.[][]'
```

`.` and `.[]` are *filters*. In jq every filter has an input and an output, and
you can pipe the output of one filter into the input of another filter: 

```
echo '[["foo"],["bar"]]' | jq '.|.[]|.[]'
```

Jq has *lots* of filters, and at first glance, many of them will seem useless
and silly. For example, any string literal works as a filter that drops it's
input and outputs itself: 

```
echo '[["foo"],["bar"]]' | jq '"best filter ever"'
```

Why on earth would you ever want a filter that ignores the input and outputs
itself? Well let me introduce you to the `,` operator; it *tee's* the input to
whatever it separates. We can use the comma and string literals together to
make record separators: 

```
echo '["foo"]["bar"]' | jq '.,"************"'
```
