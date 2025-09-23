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
terraform init -upgrade

terraform plan -var project_id=<project-id> -var region=us-central1 -var jenkins_hostname=jenkins.example.com -var app_hostname=app.example.com \
    -out=tfplan.binary

terraform apply tfplan.binary


# Check if everything is right
terraform output

```

Don't forget to decomiission to avoid extra charges:

```bash
cd infra
terraform destroy -auto-approve
```



## Minimal repo structure

```
./Jenkinsfile
./Dockerfile
./.dockerignore
./charts/
   /your-app/           # Helm chart
      /Chart.yaml
         values.yaml    # override ingress.className=gce + static IP annotation 
         templates/...
./src/                  # app code
   ...

```

