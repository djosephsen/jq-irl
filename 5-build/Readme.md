# Section 5:

This chapter contains a bunch of real shell scripts written by me or other engineers
I know that are worth studying, along with accompanying descriptions.


## findInstance.sh

```
#!/bin/sh
# lookup and return a summary of the aws metadata for either a given InstanceID, or a partial (case sensitive) Tag

function usage {
   echo "findinstance: lookup and return a summary of the aws metadata for either a given InstanceID, or a partial (case sensitive) Tag"
	   echo "usage: findinstance (<tag>|<InstanceId)"
		   exit 42
			}

			[ "${1}" ] || usage

			STATES=pending,running,shutting-down,stopping,stopped

			if echo ${1} | grep -q '^i-'
			then
			      aws ec2 describe-instances --instance-ids ${1} --filters  Name=instance-state-name,Values=${STATES} | jq ".[][].Instances[]|{\"----------------Instance-------------------\",InstanceId, ImageId, Tags, InstanceType, LaunchTime, PublicIpAddress, PrivateIpAddress, PublicDnsName, PrivateDnsName, SecurityGroups}"
					   else
						      aws ec2 describe-instances --filters  Name=instance-state-name,Values=${STATES} | jq ".[][].Instances[]| select(.Tags[]?.Value? | index(\"${1}\")) | {\"----------------Instance-------------------\",InstanceId, ImageId, Tags, InstanceType, LaunchTime, PublicIpAddress, PrivateIpAddress, PublicDnsName, PrivateDnsName, SecurityGroups}"
								fi
```


