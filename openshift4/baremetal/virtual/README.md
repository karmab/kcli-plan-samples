A full virtual env deployed and ready to be deployed by the baremetal plan

## How to

- Copy parameters.yml.sample to parameters.yml and edit the file to put your

- ssh pub key
- pull secret

- Run the following command to create the vms

```
kcli create plan --paramfile params.yml
```

- Run the following command to generate the corresponding install-config.yml

```
kcli render -f install-config.yaml --paramfile params.yml
```

- Launch openshift baremetal install using the plan in the directory one step above and by passing your install-config.yaml as one of the parameters
