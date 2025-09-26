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


gcloud services enable container.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  --project <project-id>

cd infra
terraform init -upgrade

terraform apply -target=google_project_service.container \
                -target=google_project_service.compute \
                -target=google_project_service.artifact \
                -target=time_sleep.after_services -auto-approve

terraform apply -auto-approve

kubectl -n jenkins get pods -w


# cd infra
# terraform init -upgrade

# terraform plan -var project_id=<project-id> -var region=us-central1 -out=tfplan.binary

# terraform apply tfplan.binary


# # Check if everything is right
# terraform output

```

Don't forget to decomission to avoid extra charges:

```bash
cd infra
terraform destroy -auto-approve
```



## Minimal apps repo structure

```
./Jenkinsfile
./Dockerfile
./.dockerignore
./charts/
   /your-app/           # Helm chart
      /Chart.yaml
      /values.yaml    # override ingress.className=gce + static IP annotation 
      /templates/...
./src/                  # app code
   ...

```

- Jenkinsfile at the repo root keeps Jenkins Multibranch out-of-the-box
- Dockerfile at root so `docker build .`` is straightforward
- Helm chart inside the repo so the pipeline can `helm upgrade --install` straight from the same commit that produced the image

