# AltSchool_K3s_WebApps
>This is a guide on setting up continuous deployment, container orchestration, monitoring, logging, metrics etc... using RKE2 and k3s

### Cluster Setup
_Setting up VMs can be performed on various cloud providers (eg. aws, azure, gcp, linode, even self-hosted(rancher-common)). For this example, we'd use digital ocean for their great registration bonus of $200 but other cloud providers should offer a similar step._

- Clone This repo to a folder using git clone. The folder related to this activity is `Terraform_k3s_Setup` and is gotten from here [**rancher/quickstart**](https://github.com/rancher/quickstart)

>choose the folder that matches your cloud provider. It'll be easier to follow this tutorial if you use digital ocean(do).

- Register on Digital ocean and create a personal access key with read and write permission.
See how to create [**here** (`digitalOcean`)](https://docs.digitalocean.com/reference/api/create-personal-access-token/)

- navigate to the DigitalOcean folder containing the Terraform files: `cd k3s_Setup_Terraform/rancher/do`

- Add new reposiroty secrets on Github with below Names
    - `RANCHER_DEFAULT_PASS` - this is the default admin password you want to setup rancher with
    - `DO_ACCESS_KEY` - this is the personal access token you created earlier on digitalOcean.
> If you don't want  to use Github secrets, you can navigate to `k3s_Setup_Terraform/rancher/do` folder, and rename terraform.tfvars.example to terraform.tfvars; then customize the variables.

- Optional: Modify optional variables within `variables.tf` or your tfvars, if you're using that. eg.

    - `do_region` - DigitalOcean region, choose the closest instead of the default (nyc1)
    - `prefix` - Prefix for all created resources


- navigate to the github workflows. If you're in the terraform do folder then: `cd ../../../.github/workflows`
- Set the `Applied` value to `false` to indicate that your environment is new or that there are new changes that are yet to be applied to the environment.

```
env:
  Applied: 'false'
```
- If this is **not** your very first workflow run, you'll need to make a change in the the `k3s_Setup_Terraform/rancher/do` folder.
It may be negligible such as adding a random text to the readme as the action is also configured to track that. \

>Remember you can edit the workflow to track the folder of another cloud provider also.

```
on:
  push:
    branches:
    - main
    paths:
    - k3s_Setup_Terraform/rancher/do/**
```
_Changing something in the `do` folder and also setting `Applied` to `false` sort of serves as an "are you sure?" prompt._

- Optional: Modify optional variables within variables.tf or your tfvars, if you're using that. eg.
    `TF_VAR_droplet_server_size`: 's-2vcpu-4gb' #this is the minimum requirement for rancher
    `TF_VAR_droplet_node_size`: 's-4vcpu-8gb'   (this is a minimal size but can still be reduced)

- Push your code to the main branch on github and allow the github actions run.
- **This setup will create 2 clusters with 3 droplets(VMs).**
- Once it's done, look into the output of the `Terraform Apply` step in your github Action logs for text that looks like the
below(it is probably at the end of this step's logs)

```
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

rancher_node_ip = xx.xx.xx.xx
rancher_server_url = https://rancher.xx.xx.xx.xx.sslip.io
workload_node_ip = yy.yy.yy.yy
```

- Paste the `rancher_server_url` from the output above into the browser. Log in when prompted, default username is `admin`, use the password set in `RANCHER_DEFAULT_PASS` of github secrets or `rancher_server_admin_password` of terraform.tfvars earlier to log in and you will be taken to the clusters page.
> Wait for all clusters to be in `Active` State before proceeding.


- To pull down the environment, set DestroyEnv variable to true, make any kind of change in the `k3s_Setup_Terraform/rancher/do` folder and push to min. (Be careful of course)
```
env:
 DestroyEnv: 'true'
```
- Dont forget to update the `env.Applied` value to `true`

```
env:
  Applied: 'true'
```

---
# [Optional] Setup up kubeconfig and kubectl on local machine
> This Section is optional as kubectl is available in rancher cluster CLI.

> Kubeconfig allows us to access kubernetes APIs and manage our cluster though a CLI
Of course, with rancher, the mature UI can do many of the basic things desired.

- install kubectl on local device (preferably WSL2/linux but mac and windows are supported by kubectl also)
- Go to rancher UI. Your rancher url probably still looks like this: https://rancher.xx.xx.xx.xx.sslip.io
- in the side bar, naivagte to global apps and go to Cluster Management.
- click on the options(right - 3 dots) of the Custom `provider` cluster. Following the earlier steps, The cluster name should be called: `do-custom`
- download the kubeconfig and save in default location for kubectl `~/.kube` and save file name as `config`. so the file path will be `~/.kube/config`
- you can also save the kubeconfig in `.kube`. You can view a sample format in `.kube/do-custom-example.yaml` folder.
- test your connection by listing the non-local clusters with the below command
assuming your config file is called `do-custom.yaml`
```
kubectl config view --kubeconfig .kube/do-custom.yaml
```
```
kubectl config get-contexts 
```
> **VERY IMPORTANT:** if your kube config file, in your local machine, is in a custom location, always append the cobe config flag to your kubectl commands. For example, assuming your config file is called `do-custom.yaml` and you are in the root directory of the project, then the above commands will then become

```
kubectl config view --kubeconfig .kube/do-custom.yaml
```
```
kubectl config get-contexts --kubeconfig .kube/do-custom.yaml
```
---
# [Optional] Setup Monitorring and Metrics Manually
> This section is optional as we will delete this manual deployment and add it to fleet cd later on.
- navigate to socks kubernetes folder: 
`cd socks-microservices-demo/deploy/kubernetes`

- You can confirm the current cluster that kubectl is currently executing on. If you used the cluster-name of the infra.tf file as-it, then it should be `do-custom`:
```
kubectl config current-context 
```
- if you find you're interfacing with the wrong context/cluster, simply list the contexts/clusters and switch to the desired one.
```
kubectl config get-contexts
kubectl config use-context valid-cluster-name-here 
```
- [Optional] Review /manifests-monitoring folder for any customizations you would like to do.
- Now Add the monitoring workloads (while still inside `socks-microservices-demo/deploy/kubernetes` folder)

```
kubectl create namespace monitoring
kubectl create -f manifests-monitoring
```

- [Ignore this] Just some random, maybe useful commands
```
kubectl get namespaces
kubectl -n kube-system get deployments
kubectl get deployments -n logging
kubectl delete deployments kibana -n namespace-where-it-is
``` 
~~- [Optional] In `/manifests-logging-cluster` folder,
add elastic and kibana to `logging` namespace (while still inside `socks-microservices-demo/deploy/kubernetes` folder)
| kubectl create -R -f manifests-logging-cluster
| It's fine if you get an error that a resource already exists
| if you get other errors, you can just delete the namespace, wait for a while or try again.
| kubectl delete namespace logging
| go to the workload in Rancher UI `do-cluster | Deployments 
| Grafana and Prometheus will be in `Namespace: monitoring`
| Kibana will be in `namespace: kube-system`
| click on the endpoints and proceed to use their UI.~~

---
# Setup Fleet for Continuous Deployment.
> Fleet is a container management and deployment engine designed to offer users more control on the local cluster and constant monitoring through GitOps.
Fleet can also manage deployments from git of raw Kubernetes YAML, Helm charts, Kustomize, or any combination of the three. Regardless of the source, all resources are dynamically turned into Helm charts, and Helm is used as the engine to deploy all resources in the cluster

### **[Optional] install helm locally.** 
> This Section is optional as helm is available in rancher cluster CLI.
- See guide [**here** (`helm`)](https://helm.sh/docs/intro/install/).
For linux, the below will work.
You can skip this though, if you intend to run the helm command from withing the cluster's kubectl.
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh

./get_helm.sh
```
### **Setup Persistent Storage Class**
> A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It represents a storage volume that is used to persist application data.

- navigate to the `.kube` folder.
- Add the storage class (current name is `longhorn-test`)
```
kubectl apply -f storage-class.yaml
```
- if  something goes wrong, you can delete the storage class and try again eg.
```
kubectl delete storageclass longhorn-test
```

### **Install Fleet Helm charts**
> **_NOTE:_**  This step may fail if run from local device but you haven't saved your kubeconfig file  in `~/.kube` folder, **Alternatively, just run the command in the desired cluster's CLI (top right).**
- For Rancher, it is recommended to first create a namespace (eg `cattle-fleet-system`) inside a project in from UI. This would especially be important where you want elevated Pod Security Policy, which is what we would like for fleet.
```
helm -n cattle-fleet-system upgrade -i --create-namespace --wait \
    fleet-crd https://github.com/rancher/fleet/releases/download/v0.6.0-rc.5/fleet-crd-0.6.0-rc.5.tgz
helm -n cattle-fleet-system upgrade -i --create-namespace --wait \
    fleet https://github.com/rancher/fleet/releases/download/v0.6.0-rc.5/fleet-0.6.0-rc.5.tgz
```
>_Remember you can run the commands from kubectl within the desired cluster in rancher CLI(eg.`do-custom` and `local`)_

- Fleet should be ready to use now for single/multi cluster. You can check the status of the Fleet controller pods by running the below commands.
```
kubectl -n cattle-fleet-system logs -l app=fleet-controller
kubectl -n cattle-fleet-system get pods -l app=fleet-controller
```
- The last command should show something like the below
```
NAME                                READY   STATUS    RESTARTS   AGE
fleet-controller-xxxxxxx-xxxx   1/1     Running   0          3m21s
```

### **[Optional] Setup cluster Group (for multi-cluster)**
> A Cluster Group will group multiple clusters together and manage them identically.
- Navigate to the `.kube` folder.
- Edit the `kube-group.yaml` file. You can add multiple key/values under the `matchLabels` field.
- copy all it's content.
- Head over to rancher UI **GLOBAL APPS** -> **Continuous Delivery**
- Click on the drop down in the upper right and change option to `fleet-default` (this includes non-local clusters).
- Inside the page, Click on Cluster Group ->  click on create (right) -> `Select Edit as YAML`(bottom right).
- paste the content of the kube-group.yaml in the field and click Create.
> You can also create using the form UI.

- Click on the `Clusters` menu (left) 
- Select all the cluster you want to add to the group(using the left checkbox).
1 Select `Change workspace`
- Select `Add/Set Label`
- Set the key/value pair to match the newly created group (eg. `env=test`)
- Select Apply.
> If the cluster or group is stuck in `Wait-Applied` state, simpply slect the `Force Update` option.

### **Add Git Repo**

**Delete Existing namespace**
> If you have deployed workloads to a namespace (eg. using kubectl to deploy monitoring) and you want to deploy the _exact same workloads_ to the same namespace, then, it's best to delete that namespace first to avoid deployment conflict; 
If this doesnt apply to your case, then you can skip this section and move on to the next.
- Confirm or Switch to the namespace where you have deployed the socks example.

```
kubectl config get-contexts
kubectl config use-context do-custom
```
>Remember to use the --kubeconfig flag if your kubeconfig file is in a custom location eg. `--kubeconfig .kube/do-custom.yaml`
- Verify the namespace and pods that were created. eg.
```
kubectl get namespaces
kubectl get pods -n sock-shop
```
>**_NOTE:_** Deleting a namespace is a final act. Everything in the namespace including all services, running pods, and artifacts will be deleted.
- Delete the namespace and it's content
```
kubectl delete namespace sock-shop
kubectl delete namespace monitoring

kubectl delete clusterrolebinding prometheus
kubectl delete clusterrolebinding kube-state-metrics

kubectl delete clusterrole prometheus
kubectl delete clusterrole kube-state-metrics

kubectl delete ServiceAccount prometheus -n monitoring
kubectl delete ServiceAccount kube-state-metrics -n monitoring
kubectl delete ServiceAccount node-exporter -n monitoring
```

**Add Git Repo Cont'd**
- naviage to kubeconfig folder: `cd .kube`
- Edit the `socks-git-repo.yaml` file 
- Set the `repo:` **value to your own repo** (or leave it as is to reference this one).
- set the `paths:` field to your relevant manifests path(s) of the workloads you want to deploy.
- edit the cluster filters to match with your desired cluster or cluster group.
> Feel free to comment/uncomment any of the cluster selectors. There must be at least one option that can be used to correctly identify the desired cluster or cluster group.
- Copy the contents of the file.

- Go to Rancher UI (still in `Continuous Delivery` | `fleet-default`)
- Select `Git Repos` -> `Add Repository` -> `Edit As YAML`
> **ALWAYS** make sure the referenced repo has been pushed and is available online.
The scope of this guide does not cover private repos or air-gapped envoronments.

- paste the `socks-git-repo.yaml` content in rancher and select `Create`
- If unedited, Fleet will now track the manifests of socks shop and logging

> You can also use the form UI to add the GitRepo details (it's simple to do so.).
- Check the status of what the fleet is doing
```
# Downstream cluster
$ kubectl logs -l app=fleet-agent -n cattle-fleet-system
# Local cluster
$ kubectl logs -l app=fleet-agent -n cattle-local-fleet-system
```
```
kubectl -n cattle-fleet-system logs -l app=fleet-controller
kubectl -n cattle-fleet-system get pods -l app=fleet-controller
```

> If you encounter an inssuficient memory/cpu error on the deployment, you would need to scale up the cluster nodes or add more nodes to the cluster.
> if you encounter an error that a resource already exists, then you might need to delete the resource manually first.
eg.

```
Rendered manifests contain a resource that already exists. Unable to continue with
 install: ClusterRoleBinding "fluentd" in namespace ""
```
then
```
kubectl get clusterroles
kubectl get clusterrolebindings
kubectl get ServiceAccount -n kube-system

kubectl delete clusterrolebinding fluentd
kubectl delete clusterrolebinding prometheus
kubectl delete clusterrolebinding kube-state-metrics


kubectl delete clusterrole fluentd
kubectl delete clusterrole prometheus
kubectl delete clusterrole kube-state-metrics


kubectl delete ServiceAccount fluentd -n kube-system
kubectl delete ServiceAccount prometheus -n monitoring
kubectl delete ServiceAccount kube-state-metrics -n monitoring
kubectl delete ServiceAccount node-exporter -n monitoring
```
> **_NOTE:_**  Be cautious when dealing with roles and role baindings

> If something else goes wrong, you can delete the repo, wait a while for any created namespaces to be deleted, then try again.

### **Customizing Socks Demo**
> Dependency on nginx-ingress has been included in socks shop example
- Ingress and ingress controllers residing in RKE-launched clusters are powered by Nginx.
navigate to ingress folder `cd  socks-microservices-demo\deploy\kubernetes\helm-chart`
- Edit `values.yaml`

**[Optional] Adding Custom DNS**
- In your domain provider's portal, add the IP of any of the cluster servers to the A records (ingress will route them automatically).

- generate certificate signing request.
- Head over to the CLI in your cluster [>_] (top right) and generate private key(follow through with all the prompts).
```
openssl genrsa -out myuser.key 2048
openssl req -new -key myuser.key -out myuser.csr
```
- find the private key
```
ls *.key
```
- from the above result, print out the key contents and save somewhere secure for now eg.
```
cat myuser.key
```
- find the csr directoy
```
ls *.csr
```
- from the above result, print out the csr contents eg.
```
cat myuser.csr
```
- Copy the csr file contents and submit with your domain provider.
- your domain provider will provide a certificate, copy and save that too. 
> we will use the rancher secret manager to apply the secret for security purposes.
- Naviage to your cluster - `More Resources | Core | Secrets`
- Click Click `Create`. -> `TLS Certificate`
- Enter a **unique** name for the secret(lowercase)(eg. external-tls).
- select the namespace where the socks demo app will be deployed.(eg.socks-shop)
- In the Private Key field, copy and paste your certificate's private key into the text box (include the header and footer).
- In the certificate field, copy and paste the certificate given to you(usually, you can copy everything provided in the test or file).
Click Create.
- navigate to the helm chart folder `cd socks-microservices-demo\deploy\kubernetes\helm-chart`
- Edit the values.yaml
- Add your domain hostname to `host` field without the prefix (eg. host: **yourdomain.com**).  **dont** prefix it with www. or https://)
- Add the secret name of the secret that you created to `tlsSecretName:` (eg. tlsSecretName: 'external-tls')
- save your changes and push to your repo, Fleet will automatically appy the changes.

>Let your imaginations run from there. But don't forget the operating costs and carbon emissions caused by using kubernetes. 😊

