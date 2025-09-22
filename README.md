# Terraform + Jenkins + GKE

- Create GKE cluster
- Create artifacts registry
- Create static IP address
- Create instance to run a node
- Create k8s namespaces
- Set up Jenkins


Quick start:
```bash
gcloud auth login
gcloud config set project <project-id>

cd infra
terraform init
terraform apply -auto-approve \
  -var project_id=<project-id> \
  -var region=<region> \
  -var jenkins_hostname=jenkins.your-host.tld

# Check if everything is right
terraform output

```

Don't forget to decomiission to avoid extra charges:

```bash
cd infra
terraform destroy -auto-approve
```

