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
Lets get a list of just the `PublicDNSName` from every instance: 

## The question mark
Ok, here is a very important, life-saving operator that you're going to hate
yourself for forgetting about later. The `?` operator protects you in the event
that you ask for something that doesn't exist. Lets say for example that we
want to extract all of the tags from every instance. We might use something
like this: 

```
jq '.[][].Instances[].Tags[]' in.json
```

Notice, however that JQ exited early with an error message: 

```
jq: error (at in.json:11960): Cannot iterate over null (null)
```

This is because some of our Instance objects didn't contain a `Tags` object, so
for a few of these objects, we asked jq to iterate over nothing. By default, jq
assumes that's not actually what we want, so it throws an error to let us know
something went wrong.  Lets quantify the number of Tags per Instance object: 

```
jq '.[][].Instances[].Tags | length'  in.json | sort | uniq -c
```

Yep, three instances have no Tags whatsoever. That's annoying, but we can
protect ourselves using the `?` operator like so: 

```
jq '.[][].Instances[].Tags[]?' in.json
```

Now jq assumes we know what we're doing, and simply prints nothing rather than
warning us that it can't iterate over nothing. Lets use the `?` operator to get
a list of all the Tag Keys from all of our instances (I'll sort and unique it
to remove the duplicates). 

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
provide, and if that expression evaluates to "true", select outputs 

## Excercise 4
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

Filters like this also work with string matching, eg:

```
jq '.[][]|select(.Instances[].InstanceId=="i-xxxef129")' in.json
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
The easiest way to do this is simply to provide the input we want, first, and
then filter out the objects that match the subset of that input. It's really
important to ALWAYS be cognizent of the *input* that is flowing into each
filter. When in doubt, make sure any filter you're having trouble with is
getting the input you expect.
