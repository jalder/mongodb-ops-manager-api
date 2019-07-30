import requests
from requests.auth import HTTPDigestAuth

base_url = 'http://{OM-URL}:8080/api/public/v1.0'
user = '{OM-USERNAME}'
apiKey = '{OM-APIKEY}'

response = requests.get(base_url+'/groups', auth=HTTPDigestAuth(user, apiKey))
orgs = response.json()

print('"Hostname","Version","Type","Cluster Name/Replica Set Name","Last Ping", "Org/Project Name"');

for project in orgs['results']:
  ## get Org details, this could be optimized to not call multiple times
  response = requests.get(base_url+'/orgs/'+project['orgId'], auth=HTTPDigestAuth(user, apiKey))
  orgs = response.json()

  response = requests.get(base_url+'/groups/'+project['id']+'/hosts', auth=HTTPDigestAuth(user, apiKey))
  hosts = response.json()
  
  for host in hosts['results']:
    if 'clusterId' in host.keys() or 'replicaSetName' in host.keys():
      ## get Cluster name/details
      response = requests.get(base_url+'/groups/'+project['id']+'/clusters/'+host['clusterId'], auth=HTTPDigestAuth(user, apiKey))
      clusterDetails = response.json()
      cluster = clusterDetails['clusterName']+'/'+clusterDetails['replicaSetName']
    elif host['typeName'] == 'SHARD_MONGOS':
      ## clusterId appears to not be present on mongos hosts
      response = requests.get(base_url+'/groups/'+project['id']+'/hosts/'+host['id'], auth=HTTPDigestAuth(user, apiKey))
      hostDetails = response.json()
      for link in hostDetails['links']:
         if link['rel'] == "http://mms.mongodb.com/parentCluster":
           response = requests.get(link['href'], auth=HTTPDigestAuth(user, apiKey))
           clusterDetails = response.json()
           cluster = clusterDetails['clusterName']+'/mongos'
    else:
      cluster = ''

    print('"'+host['hostname']+':'+str(host['port'])+'","'+host['version']+'","'+host['typeName']+'","'+cluster+'","'+host['lastPing']+'","'+orgs['name']+'/'+project['name']+'"')


