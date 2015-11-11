#Section 4

JQ has A LOT of functionality. Far more than I can cover in 90 minutes. But at
this point, you have a good 85% of what I think you need for day-to-day glueing
together API's in shell, and writing simple little tools to help preserve your
sanity when interacting with things like the AWS CLI tools. In fact I'd even
say you have about 95% of what you need to query most API's and explore the
vast, cumbersome structures they return.

Now we're going to talk about cherry-picking data out of those structures and
creating, well, new structures from them. This is suprisingly easy with JQ,
though it can get muddle the syntax a little bit. To create a new object in jq,
you simply wrap your output in brackets. Lets say for example, you have a
filter that returns the private IP address of every instance:

```
jq '.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress' in.json
```

But what you actually *want* is an array containing the private IP address of
every instance. Welp, just wrap that whole thing up in brackets like so:

```
jq '[.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress]' in.json
```
... and JQ will build it into a proper JSON array for you with commas and
everything. Do you remember talking about the `,` operator back in [Section
0](/0-basics) and [Section 1](/1-explore)?  We defined the comma as a filter
that *tee's* or copies the input to the filters on either side of it. We also
defined a string literal as a filter that drops it's input and output's itself
instead. Check out this filter: 

```
jq '["foo","bar"]' in.json
```
As you'd expect, it outputs an array with two elements: "foo" and "bar". But
think for a moment about *HOW* jq is doing this, given what we know about all
the individual componants of this filter statement. First, we have a comma
operator, so the input from in.json is copied first to the filter "foo", and
then to the filter "bar". Of course foo and bar are both string literals, they
are filters that parrot themselves as output. Try it without the brackets:

jq '"foo","bar"' in.json

See? The comma in the output above was added by our square brackets (The comma
in the output is not the same comma that we're using in our filter statement.
*That* comma is a valid JQ filter which copies the input to multiple outputs).
Wrapping this whole thing in square brackets told JQ to build an array from our
output, which in this case was two strings, foo and bar, so in the end, we
wound up with a valid JSON array containing two strings. I'm hoping that blew
your mind just a little bit, because the literal syntax for a valid JSON array,
is also the literal syntax of a filter statement JQ used to build a valid json
array from two given string literals. This also works with object syntax:

```
jq '{"foo":"bar","biz":"bash"}' in.json
```

Here our comma filter copies the output to two key-value pair filters which
output themselves and etc.. The fun part is, we don't need to stop at string
literals, we can substitute in any other filter expression, like so:

```
jq '{"IP":.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress}' in.json
```
Now we've transformed our list of IP addresses into a series of objects, each
of which has a key called "IP" and a value that is the IP address of each
instance in the input. We could use another set of brackets to wrap all of
those up into one big array:

```
jq '[{"IP":.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress}]' in.json
```

... or we could even wrap this up in an object named AllMyIPs.

## Excercise 8
Wrap this up in an object named AllMyIPs

## Excercise 9
AWS instance objects are large and ponderous. Create a jq filter that returns
all of the instances, in in.json but filters out all of the attributes except
InstanceId, Tags, and PrivateIpAddress

Ok, check this out:

```
jq '[.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress] | [.[]|.+"/24"]' in.json
```

There are two filter sections here. The first one you should be familiar with,
parses out the PrivateIPAddress from each instance and returns all of them as
one large array. The second part, the part that looks like this:
`[.[]|.+"/24"]` is using a `+` operator (which I briefly glossed over in
[Section 2](/2-select) to append a CIDR mask to the end of each of our IP's but
lets reason for a moment about HOW it's accomplishing this.

If we simplify/genericize the `.+"/24"` part of the filter to `X` where `X` is
some random function we want to apply, we get this: 

```
[.[] | X]
```

That's a little easier to squint at. It says unwrap one level of the input
(`.[]`), pipe each input element to X (`| X`) and then wrap the output up in
one big array (the enclosing brackets).

What you're looking at here is the definition of another built-in filter called
`map(x)`. Maps job is to unwrap one layer of it's input, feed each element to
x, and then wrap the answer back up in one big array. We could have rewritten
our filter above as: 

```
jq '[.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress] | map(.+"/24")' in.json
```

Any time you have a list of things, and you want to apply some filter to each
item of the list, and get back a list of the answer, map is what you're looking for. 

## Excercise answers

### Wrap this up in an object named AllMyIPs

Just go one level deeper with the brackets (<insert inception joke>):

```
jq '{"AllMyIPs":[{"IP":.[][].Instances[]|select(has("PrivateIpAddress")).PrivateIpAddress}]}' in.json
```

### Building New Objects to filter out everything but the attributes you want.

The first part is easy, make a filter that returns all the instances: 

jq '.[][].Instances[]' in.json

And then pipe that to an object builder that gives you just what you want: 

jq '.[][].Instances[] | {"InstanceId":.InstanceId,"Tags":.Tags,"PrivateIpAddress":.PrivateIpAddress}' in.json

That's kind of long and annoying to type out though. But fear not! JQ has a
shortcut syntax for the same thing: 

jq '.[][].Instances[] | {InstanceId,Tags,PrivateIpAddress}' in.json

If you're building an object, you can specify the name of valid attribute in
the input (without prefacing it by a dot or surrounding it in string quotes)
and JQ will substitue in valid key/value syntax for that attribute. 
