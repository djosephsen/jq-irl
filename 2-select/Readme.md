# Section 2 

The json objects that represent our instances are probably under
`.Reservations.Instances`. Lets see what kind of thing `Instances` is:

jq '.[][0].Instances | type' in.json

Ok, so it's an array. By now it should be pretty clear that we can traverse and
inspect to any depth in this structure. Lets see if we can craft a filter to
*just* return all of the *instances* objects:

```
jq '.[][].Instances' in.json
```

## Excercise 2: 
Lets get a list of just the `PublicDnsName` from every instance: 

So depending on how you formed your filter, you might notice that there are
blank spaces in the output of this command. This is because some of our
instances don't *have* values for their PublicDnsName attributes.

## The question mark
This leads me to a very important, life-saving operator that you're going to
hate yourself for forgetting about later. The `?` operator protects you in the
event that you ask for something that doesn't exist. 

If, for example, we want to extract all of the tags from every instance. We
might use something like this: 

```
jq '.[][].Instances[].Tags[]' in.json
```

Notice, however that JQ exited early with an error message: 

```
jq: error (at in.json:11960): Cannot iterate over null (null)
```

To understand where this error is coming from, lets ask jq what kind of thingy
tags is (the easiest way to do that is to isolate it by asking for the first
instance in the first reservation:

```
jq '.[][0].Instances[0]' in.json 
```

And then isolating the tags for that single instance:

```
jq '.[][0].Instances[0].Tags | keys,type' in.json
```

And we see that in that instance, tags is an array with three elements. So if
we ask for `Tags` from EVERY instance, we get a bunch of arrays. One array from
every Instance, and if the Tags array for a particular Instance is blank, well
then we get an empty array.

```
jq '.[][].Instances[].Tags'  in.json  
```

But if we ask for `Tags[]`, then what we're really asking for is the contents
of each of those arrays, Please JQ, for each of these arrays iterate through
it, and return me its contents. So if an instance has an empty Tags array, then
we're asking jq to iterate over null. By default, jq assumes that's not
actually what we want, so it throws an error to let us know something went
wrong.  Lets quantify the number of Tags per Instance object: 

```
jq '.[][].Instances[].Tags | length'  in.json | sort | uniq -c
```

Yep, three instances have no Tags whatsoever. That's a problem because JQ will
stop processing the input at the first null array it encounters so we don't
know how much input we've actually processed. But we can protect ourselves
using the `?` operator like so: 

```
jq '.[][].Instances[].Tags[]?' in.json
```

Now jq assumes we know what we're doing, and simply prints nothing when it
encouters an empty tags array rather than warning us that it can't iterate over
nothing. I think it's really powerful that you can toggle this behavior for
individual arrarys in a stream like this. 

Lets use the `?` operator to get a list of all the Tag Keys from all of our
instances (I'll sort and unique it to remove the duplicates). 

```
jq '.[][].Instances[].Tags[]?.Key' in.json | sort | uniq
```

Look at that, one of our tags is *"Role"* what if we wanted a list of Roles? We
would have to select out *just* the tags that contained a `Key` attribute that
matched `Role`. Well allow me to introduce the `select` filter.

```
jq '.[][].Instances[].Tags[]?|select(.Key=="Role")'  in.json
```

The `select` filter is pretty simple, it copies its input to the expression you
provide, and if that expression evaluates to "true", select spits out it's
input unchanged. Otherwise it eats it's input. So how would we extract  

## Excercise 4
Modify the select filter above to return the entire Instance object, for every
instance that has a `Role` Tag. 

## Excercise 5 
Modify the filter you created in Excercise 4 to return *just* the
`PrivateIpAddress` of the instances that have a `Role` key

## Excercise 6
Use the select filter to return just the objects inside reservations that have
5 thingies in them:

## Excercise answers: 

### Get a list of just the `PublicDnsName` from every instance
```
jq '.[][].Instances[].PublicDnsName' in.json
```
If you got blank-output, you probably misspelled something (PublicDNSName
instead of PublicDnsName perhaps?).  If you got an error, you were probably
asking for an invalid path (ie you forgot the [] after instances (remember, you
need brackets any time you want the *stuff inside* the thing you're naming). If
you nailed it you're better at this than I am. 


### Return the entire Instance object, for every instance that has a `Role` Tag
```
jq '.[][].Instances[]|select(.Tags[]?.Key=="Role")'  in.json
```
Here we've "borrowed" `.Tags[]` from the input filter, and appended it to the
select filter instead. This had the effect of changing our input to a list of
instances rather than a list of tags, and therefore our output was also
transformed to a list of instances rather than tags. Remember select() merely
parrots back its input when the expression inside it returns `true`.

### Return just the `PrivateIpAddress` for each instance that has a `Role` tag
```
jq '.[][].Instances[]|select(.Tags[]?.Key=="Role")|.PrivateIpAddress'
```
Here's we've simply bolted on another filter to output the subset of Instance
attributes we want to print out. This is a pretty common problem, where you
really want Attribute X, but you only want it from objects that have Attribute
Y.

It's ok if all of your IP addresses are 1.2.3.4 because this dataset has been
anonymized.

### Return just the objects inside reservations that have 5 thingies:
``` 
jq '.[][] | select(length==5)' in.json 
```
Jq filters often work together in suprisingly powerful ways. Here, we use the
length filter we learned in section 1 nested inside a select filter.  

You can verify that these are the correct reservations with: 

``` 
jq '.[][] | select(length==5) | keys' in.json | sort | uniq -c 
```

JQ supports the full-range of equality operators you'd expect so all of these
are also valid: 

``` 
jq '.[][] | select(length != 4) | keys' in.json | sort | uniq -c 
jq '.[][] | select(length > 4) | keys' in.json | sort | uniq -c 
jq '.[][] | select(length >= 4) | keys' in.json | sort | uniq -c 

```
We can even use math operators like `+`, `-`, and `*` to perform math on
numbers in our input, and append strings to other strings.  Also, it should go
without saying that there's no difference between string matching and number
matching syntax eg:

```
jq '.[][]|select(.Instances[].InstanceId == "i-xxxef129")' in.json
``` 

## Bonus question: 
Notice that the select statement immediatly above ^ returns the *reservation
object* that contains an instance whose instance id is equal to i-xxxef129.
How might we return just the *Instance object* whose instance id is equal to
i-xxxef129? 


### Bonus question answer: 
```
jq '.[][].Instances[] | select(.InstanceId=="i-xxxef129")' in.json
```
This is really a restatement of Excercise 4, but it bears repeating. The
easiest way to get the output you want out from `select()` is to give it the
*input* you want in the first place, and then use `select()` to filter out the
objects that match the subset of that input. In general with JQ it's really
important to ALWAYS be cognizent of the *input* that is flowing into each
filter. If you're having trouble, break down and isolate each filter and make
sure each is getting the input you expect.
