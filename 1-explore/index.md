# Exploring new JSON structures

In real life, you're usually dealing with large complicated structures with
highly variable content. `in.json` contains anonymized input from the AWS-CLI
command: `aws ec2 describe-instances`.  We're going to use the jq filters: `,`,
`type`, `length`, and `keys`, to explore this data structure. 

We'll start by asking jq to give us the type, and length of whatever is at the
top layer of this structure.

``` jq 'type,length' in.json ``` 

Remember, when we separate filters with a comma, the input is copied to both
filters.  Here we have two filters, type, which outputs the type of all the
thingies on its input, and length which counts the elements of each thingie on
its input.

Ok, now we know that `in.json` consists of a single object that contains a
single... something, we don't know yet, so lets say it has one thingie in it.
Since objects always contain key value pairs, and this is an object, we can
assume this thingie inside it has a name. We can see that by calling keys on
the top-level object like this: 

``` jq 'keys' in.json ```

Now we can see the top level object contains something named Reservations, but
we don't know what kind of thingie it is. Lets ask for it's type: 

``` jq '.[]|type' in.json ```

That time we had to add *unwrappy brackets* because we don't want the type of
the top level object (we already know that's an object), we want the type of
the thing *inside* the top level object. Now check this out:

``` jq 'keys,(.[]|type)' in.json ```

Wow, we're already starting to look like we know what we're doing. All we've
done is join the two filters we just used with a comma, and since the type
command used two filters with a pipe, we went ahead and grouped them with
parenthesis; which is totally a thing you can do to be explicit about what you
want. So when we run this command jq sends a copy of the input to keys, which
returns the name of our thingie (which we already know is `Reservations`), and
then it sends another copy to our unwrap-pipe-to-type filter, which returns
it's type which happens to be `array`. 

Lets see how many elements are in this reservations array..

```
jq '.[] | length' in.json 
```

We've used square brackets to unwrap the top level object again. Empty brackets
give us a way to refer *generally* to the stuff *inside* the thing. When we do
this, JQ basically scraps one layer of wrapper brackts and provides whatever
was inside those brackets as raw output. But since we know the array's name, we
also could have explicitly named the array instead like so:

``` 
jq '.Reservations | length' in.json 
```

Nice. We can refer to the names of things! Incidently, this is actually a
short-hand syntax for a string index. In other words, we *ALSO* could have
explicitly asked for Reservations by name like so: 

``` 
jq '.["Reservations"] | length' in.json 
```

Hey it's those brackets again. So it turns out we can also use brackets to
refer to *array* elements by number, eg: `.[0]`. So if we wanted to print the
first element of the reservations array, we might say: 

``` 
jq '.Reservations[0]' in.json 
```

So to be clear, we can refer to *object names* by using the dot notation
shortcut (like `.Reservations`), but we always have to refer to *array indices*
using brackets with a number (like `.[0]`)

...but I digress. Lets see what's inside this Reservations array:

``` 
jq '.[][]|type' in.json 
```

Remember we can stack brackets to go as deep as we want. But the output from
that command scrolls off my screen, so I'll bring bash in to help: 

``` 
jq '.[][]|type' in.json | sort |uniq -c 
```

Ok, so our Reservations array contains 140 objects. 

Incidently: if we call keys on an array, we just get numbers back since arrays
are indexed by number...

``` jq '.[]|keys' in.json ```

But if we go down one more level, we get the keys of each of the array elements
inside reservations: 

``` jq '.[][]|keys' in.json ```


## Excercise 1: 
Count the number of thingies inside each of the 140 objects in the reservations
queue. 

Do they all contain the same number of thingies?


## Excercise 2: 

How many of each type of object exists (ie, how many objects have four thingies
vs five thingies?)


### Bonus:
List the keys that differ between the objects of each type


## Excercise answers: 

HEY! no peeking. Oh, you're done. Ok my bad go ahead... 

To get the number of thingies inside each object you can add ```length``` to
the filter we used to find their type above ^^ (pro tip: type and length work
very well together when you're trying to figure out a new json structure)

``` jq '.[][]|type,length' in.json ```

In that output we can see that some objects have 4 thingies and others have 5
thingies, but again, it scrolls off my screen since there are 140 of them. We
can pipe out to ```sort | uniq -c``` to get a breakdown of each type of object.

``` jq '.[][]|type,length' in.json | sort | uniq -c ```

That shows us there are 131 objects with 4 thingies in them, and 9 objects with
5 thingies in them. 

For the bonus question, we can start by getting a list of the keys in each
object by asking for keys instead of type and length. 

``` jq '.[][]|keys' in.json ```

Now notice that the keys filter returns us an *array* of the keys found in each
object. we can pass this output back to sort and uniq to get a breakdown by
object.

``` jq '.[][]|keys' in.json | sort | uniq -c ```

Now we can see that the objects with four thingies are a subset of the objects
with five thingies. The 5-key ojects contain all the same keys that the 4-key
objects do, but they contain one extra key, which is RequesterId.

Nice job! See you in lession 1!
