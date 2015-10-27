# jq-irl

This is the text version of my [LISA
mini-tutorial](https://www.usenix.org/conference/lisa15/conference-program/presentation/josephsen_mini_tutorial)
on gluing together web-api's with bash, curl, and JQ.

[Section 0](/0-basics/) Covers some curl intricacies and introduces JQ

[Section 1](/1-explore/) Begins our crash-course in JQ by exploring some output from the aws cli

[Section 2](/2-select/) Shows you how to select-out and filter json objects to get just want you need

[Section 3](/3-contains/) A short digression into checking if one thingy is inside another thingy

[Section 4](/4-map/) Shows you how to re-form existing json structures into new ones, and introduces the `map()` filter.

[Section 5](/5-build/) Comes full circle, using JQ, curl, and bash to glue together some
third party API's and make some interesting tools.
