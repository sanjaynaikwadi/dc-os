# This script creates deploys Portworx Elastic. It creates a service account, grants it
# permissions, and then deploys the service definition in this directory.
#
# It uses the `dcos` CLI, so will deploy to whichever cluster the CLI is currently
# authenticated in.

# Set your service name and principal user 
role=portworx-elastic-role
service=portworx-elastic
principal=portworx-elastic-principal


dcos security -h >/dev/null 2>&1
if [[ $? != 0 ]]; then
	RED=$(tput setaf 1)
	NORMAL=$(tput sgr0)

	printf "You need to install the dcos-enterprise CLI to run this script. Please run the following command and try again: \n${RED}dcos package install --cli dcos-enterprise-cli ${NORMAL}"
	exit 1
fi

 echo "Creaing Portworx Service Account..."
 dcos security org service-accounts keypair temp-priv.pem temp-pub.pem
 dcos security org service-accounts create -p temp-pub.pem -d "Portwrox service account" $principal
 dcos security secrets create-sa-secret --strict temp-priv.pem $principal $service/mesos-auth-secret
 rm -f temp-priv.pem temp-pub.pem

echo "Creating Portworx Permmissions"
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:root \
	-d '{"description":"Allows Linux user root to execute tasks"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody \
	-d '{"description":"Allows Linux user nobody to execute tasks"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:$role \
	-d '{"description":"Allows a framework to register with the Mesos master using the Mesos default role"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:slave_public \
	-d '{"description":"Allows a framework to register with the Mesos master using the Mesos default role"}' \
	-H 'Content-Type: application/json'

echo "Assigning Portworx Permissions"
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:$role/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:slave_public__$role/users/$principal/create
curl -k -X PUT__\
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:root/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:$role/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:slave_public__$role/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:slave_public:/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:$role/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:slave_public__$role/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:slave_public:/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls//dcos:mesos:master:reservation:principal:$principal/users/$principal/delete
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls//dcos:mesos:master:volume:principal:$principal/users/$principal/delete
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:root/users/$principal/create
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:task:user:nobody/users/$principal/create

curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:$role \
	-d '{"description":"Controls the ability of portwrox-role to register as a framework with the Mesos master"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:framework:role:slave_public:* \
	-d '{"description":"Controls the ability of portwrox-role to register as a framework with the Mesos master"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT  \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:$role \
	-d '{"description":"Controls the ability of $role to reserve resources"}' \
	-H 'Content-Type: application/json'

curl -k -X PUT  \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:role:slave_public:* \
	-d '{"description":"Controls the ability of slave_public/$role to reserve resources"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:$role \
	-d '{"description":"Controls the ability of $role to access volumes"}' \
	-H 'Content-Type: application/json'

curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:role:slave_public:* \
	-d '{"description":"Controls the ability of $role to access volumes"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:reservation:principal:$principal \
	-d '{"description":"Controls the ability of $principal to reserve resources"}' \
	-H 'Content-Type: application/json'
curl -k -X PUT \
	-H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:mesos:master:volume:principal:$principal \
	-d '{"description":"Controls the ability of $principal to access volumes"}' \
	-H 'Content-Type: application/json'

dcos security org users grant dcos_marathon dcos:mesos:master:task:user:root create
dcos security org users grant dcos_marathon dcos:mesos:master:task:user:nobody create
dcos security org users grant $principal dcos:mesos:master:framework:role:slave_public/$role create
dcos security org users grant $principal dcos:mesos:master:framework:role:slave_public/$role delete
dcos security org users grant $principal dcos:mesos:master:framework:role:$role delete
