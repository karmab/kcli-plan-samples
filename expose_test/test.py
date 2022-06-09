from requests import post

create_url = 'http://127.0.0.1:9000/exposecreate'
delete_url = 'http://127.0.0.1:9000/exposedelete'
plan = 'cluster1'

# the data to be provided when creating is the plan name and then any parameter needs to be prefixed with parameter_
data = {'plan': plan, 'parameter_number': 4}
req = post(create_url, data=data)
if 'created' in req.text:
    print("Success")

# the delete operation is done using AJAX in the web, so the corresponding handler function returns json
req = post(delete_url, data={'plan': plan})
print(req.json())
