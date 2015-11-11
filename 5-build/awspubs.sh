#Credit: Mark Bainter
echo 'Configuring ip ranges:'

IPJSON=$(mktemp)

CODE=$(curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' --write-out "%{http_code}" --output "${IPJSON}")

if [ "${CODE}" -ne "200" ]; then
  echo "IP Range file could not be downloaded (${CODE})"
    exit 1
	 fi

	 PERMS=$(jq '.prefixes | map(select(.region? == "us-east-1")?) | map({"CidrIp": .ip_prefix}) | [{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": . }]' "${IPJSON}")

	 ec2_cmd authorize-security-group-ingress --group-id "${sgid}" --ip-permissions "${PERMS}”
