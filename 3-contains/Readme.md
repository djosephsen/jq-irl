# Section 3: 

Now that you understand `select()`, I'd like to take a short aside to talk
about checking for the presence of thingies inside other thingies, since you'll
pretty often want to use JQ to give you all the records of type X, but only if
they contain object Y.  The typical pattern, as we've already seen is to nest
another filter inside `select()`, which is very powerful because there are
[quite a few filters](https://stedolan.github.io/jq/manual/) we can choose.

Because of its name, `contains()` is often mistakenly chosen for this purpose.
It's a filter that compares *two like objects* against each other.  If it's
argument is *wholly contained* within it's input, then it exits "true",
otherwise it exits "false".  There are two really important ideas in there that
new-comers often get tripped up on. The first is the *like objects* part. You
can compare a string to a string.. 

```
echo '"foo"' | jq 'contains("foo")'
```

... or you can compare an array to another array...

```
echo '["foo","bar"]' | jq 'contains(["foo"])'
```

... but you *CAN'T* compare an array and a string:

```
echo '["foobar","biz"]' | jq 'contains("foo")'
```

^ that last command will error out with a somewhat confusing error message
about things having their containment checked, but what it means is you're
trying to use `contains()` to compare two different types of things. 

You may have noticed above that `contains()` returned true when we asked it if
the foobar array contained foo. This is the second problem with contains, it's
basically a substring match, it will answer true any time it's argument is
wholly contained within the input, even if the input has more going on.  So if
you're not aware that `contains()` is a substring match, it might appear to be
working when in fact it's returning too many results (or results that only
*sort of* match). 

Anyway, like I said, it's pretty common to nest `contains()` inside `select()`
like so: 

```
jq '.[][]|select(keys|contains(["ReservationId"]))' in.json
```

Where the intent of this query is to return the reservations that contain a
`ReservationId`. That *sort* of works, but check this out: 

```
jq '.[][]|select(keys|contains(["Reserv"]))' in.json
```

See what I mean? Again, because `contains()` is a substring match, it gives the
same output for 'Reserv' which isn't a real attribute, but it *is contained* in
ReservationId.  `contains()` would also break if our input contained both
ReservationId and ReservationIdStatus because it would return instances that
contained either of these attributes.

As a new JQ user myself, I've grown very suspicious of `select(contains())`, it
seems to me most of the time someone uses it, what they *really* want is one of
the following:

`select(inside())` : Inside is the inverse of contains, it requires that the
*input* is wholly contained within the *argument*. In other words, it doesn't
act like a substring match on the input and is therefore safer with respect to
false positives, but it's also only good for exact matches (ie it can't detect
if an array contains a single given element). 

`select(index())` : index is what you want when you want to check if an array
contains a string. More on it below.

`select(has())` : has is what you want when you want to check if an object
contains a key, or if an array contains something at a named index.

The naming of these filters, as well as the distinction between them can be a
little difficult to understand at first. Generally if you want to check if
something has a given *value*, use `index` (eg what index is "foo" at?), but if
you want to check if something has a given *key* (either string or numeric, eg
does this object have a "foo" key?), use `has`. 

So, following from the broken select(contains()) example above, we can use
`index()` inside a `select()` instead of contains, along with `keys` to return
every reservation that has a ReservationId key...

```
jq '.[][]|select(keys|index("ReservationId"))' in.json
```
to be clear, what's happening there is that we're converting the input to a
bunch of arrays of key names inside the select, and then we're checking those
arrays for the VALUE "ReservationId" (REMEMBER, use `index()` to check for
VALUES). 

Note that we can test the string "ReservationId" directly instead of having to
wrap it in array brackets like with contains. `index()` is designed to check a
string against a list and generally just does the right thing when you ask it
to perform list-context related stuff.  It also generally does the right thing
with respect to stirng matching, ie this doesn't work: 

```
jq '.[][]|select(keys|index("Reserv"))' in.json
```

Index is so named because it returns the index of the first element of the list
that contains what we're looking for, so if we remove the select filter like
so: 

```
jq '.[][]|keys|index("ReservationId")' in.json
```

... we can see the real output from `select()` is a stream of numbers. Each of
these represent the index where the string ReservationsID is located in each
array returned by the keys filter.  Select is interpreting those numbers as
true, but if we wanted to be more explicit, we could have written:

```
jq '.[][]|select(keys|index("ReservationId")!=null)' in.json
```

That literally says select the Reservations where the array index of the
ReservationId attribute is not equal to nothing, which is another way of saying
that the ReservationId attribute exists.  There's another version of index
called `rindex()`, which returns the index of the *last* occurance of its
argument instead of the first occurance.

Anyway, `index` only works for this because we're doing this kludgy transform of
each input object into an array of keys with `keys` first, but really what
we're actually asking here is, for each of these reservation objects, return
the ones that contain the key ReservationId, so the RIGHT way to do this would
be to use `has()`, because again, `has()` is what we use when we want to check
for a *KEY* (remember `index` is for checking values). 

```
jq '.[][]|select(has("ReservationId"))' in.json
```

WOW, that's so much better, `has` is totally what we were after from the
beginning, but at least now we (hopefully) understand the distinction between
these filters. It's pretty often the case with JQ that your first answer won't
be the optimal one, and that's OK (or at least I'm telling myself it's OK and I
recommend you do to). 

## Excercise 7
Explain the error thrown by: 

```
jq '.[][]|select(keys|has("ReservationId"))' in.json
```

## Excercise answer
The key to understanding this error is understanding the specific input that
`has()` is receiving.

Isolating it like this: 

```
jq '.[][]|keys' in.json
```

We see that `has` must be getting a bunch of arrays of key names from `keys`
which looks like this:

```
[
  "Groups",
  "Instances",
  "OwnerId",
  "ReservationId"
]
[
  "Groups",
  "Instances",
  "OwnerId",
  "ReservationId"
]
```

So what does `has` check again? It checks if the given key exists in its input
(again, use `has` to check if a thing has a given index).  And what key are we
giving it? We're giving it `"ReservationId"`. But arrays are not indexed by
strings, they're indexed by number, so by definition, it is an error to ask if
an array has a string index. We can ask `has(0)`, or `has(1)`, but we can't ask
`has("foo")`, unless our input is an object (because objects have string
indices). Remember, if we want to check if an array contains a given string
value we use `index()`!
