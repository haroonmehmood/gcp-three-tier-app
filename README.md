# Three-Tier Application Infrastructure on GCP

Terraform and Kubernetes configuration that builds a complete three-tier
environment on Google Cloud from nothing: a private network, a GKE cluster, a
standalone Compute Engine VM, and two demo workloads behind a single HTTP load
balancer.

Sized deliberately for **low cost** — roughly **$75–85/month** — so it can be
stood up, explored, and torn down without burning through credits.

## Architecture

```
                        Internet
                            │
                  ┌─────────┴──────────┐
                  │  GCE HTTP Ingress  │   one public IP
                  └─────────┬──────────┘
             /hello         │        / (default)
        ┌───────────────────┴───────────────────┐
        ▼                                       ▼
┌──────────────────┐                  ┌──────────────────┐
│ frontend (NGINX) │                  │    WordPress     │  ← presentation
└────────┬─────────┘                  └────────┬─────────┘
         ▼                                     │
┌──────────────────┐                           │            ← application
│ backend (Go)     │                           │
│ DaemonSet        │                           ▼
└──────────────────┘                  ┌──────────────────┐
                                      │  MySQL 5.6       │  ← data
                                      │  headless svc    │
                                      │  20Gi PVC        │
                                      └──────────────────┘

        all running on: GKE zonal cluster, 2 x e2-medium
        inside:         three-tier-vpc / subnet 10.1.0.0/24
```

A separate Ubuntu VM running Apache is also created. It is intentionally
independent of the cluster — a plain-IaaS counterpart to the Kubernetes side.

## Repository layout

```
.
├── main.tf              # wires the three modules together
├── variables.tf         # variable declarations
├── terraform.tfvars     # the actual values — edit this
├── provider.tf          # google provider, pinned ~> 6.0
├── backend.tf           # GCS remote state
├── outputs.tf           # cluster name, kubectl command, VM IP
├── cloudbuild.yaml      # optional end-to-end CI/CD pipeline
├── modules/
│   ├── network/         # VPC, subnet, firewall rules, optional Cloud NAT
│   ├── gke/             # GKE cluster + node pool
│   └── gce/             # Ubuntu VM + Apache startup script
├── yaml-gke/
│   ├── hello-app/       # NGINX frontend + Go backend
│   ├── wordpress/       # WordPress + MySQL + kustomization
│   └── ingress.yaml     # path-based HTTP routing
└── docker/              # reference Dockerfiles (see note below)
```

## What each module creates

### `modules/network`

| Resource | Detail |
|---|---|
| VPC | `three-tier-vpc`, no auto-subnets |
| Subnet | `us-east-b`, `10.1.0.0/24`, `us-east1`, Private Google Access on |
| Firewall | TCP 22, source configurable via `ssh_source_ranges` |
| Firewall | TCP 80 from anywhere |
| Cloud Router + NAT | **optional**, created only when `enable_nat = true` |

Private Google Access lets instances without a public IP reach Google APIs over
internal routing. Cloud NAT covers everything else (Docker Hub, apt) and is the
piece that makes private nodes viable.

### `modules/gke`

A **zonal** VPC-native cluster. Zonal matters: node counts are totals. Setting
`cluster_location` to a region instead would multiply every count by the number
of zones in that region.

- One node pool: **2 × `e2-medium`**, autoscaling 2→3
- `cos_containerd` image, 20 GB disk, auto-repair and auto-upgrade on
- Master authorized networks, and an optional private-cluster block
- `deletion_protection = false`, so `terraform destroy` actually works

### `modules/gce`

One `e2-micro` Ubuntu 22.04 LTS instance with a public IP. Its startup script
installs and enables Apache. Uses the `ubuntu-2204-lts` image *family* rather
than a pinned build, so it keeps resolving as Google publishes new images.

## Kubernetes workloads

**`yaml-gke/hello-app/`** — a Deployment running Google's sample NGINX
frontend, and a DaemonSet running a small Go backend, each with a ClusterIP
Service.

**`yaml-gke/wordpress/`** — WordPress and MySQL, each with a 20 Gi
PersistentVolumeClaim so data survives pod restarts. MySQL sits behind a
headless Service and is never exposed outside the cluster. Assembled by
`kustomization.yaml`, which generates the `mysql-pass` Secret.

**`yaml-gke/ingress.yaml`** — a single GCE Ingress. `/hello` reaches the demo
app; everything else falls through to WordPress as the default backend.

WordPress is served from the root rather than a `/wordpress` prefix on purpose.
It emits absolute redirects and absolute asset URLs, so behind a path prefix the
installer redirects to `/wp-admin/install.php`, which then matches no rule and
404s. Serving it at the root sidesteps that without needing `WP_HOME`/
`WP_SITEURL` overrides and extra rules for every WordPress path.

## Prerequisites

- A GCP project with billing enabled
- `gcloud`, `terraform` >= 1.3, `kubectl`
- A GCS bucket for Terraform state

## Deployment

### 1. Configure

Edit `terraform.tfvars` and set `project_id`. Edit `backend.tf` and set your
state bucket name. Both ship with `CHANGE-ME` placeholders.

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <your-project-id>
```

### 2. Enable APIs and create the state bucket

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com

gcloud storage buckets create gs://<your-bucket> \
  --location=us-east1 --uniform-bucket-level-access
gcloud storage buckets update gs://<your-bucket> --versioning
```

### 3. Set the database password

```bash
cd yaml-gke/wordpress
cp mysql.env.example mysql.env
# edit mysql.env and set a real password
cd ../..
```

`mysql.env` is gitignored and must never be committed.

### 4. Apply

```bash
terraform init
terraform plan      # review this before continuing
terraform apply
```

Takes roughly 10–15 minutes, mostly cluster creation.

### 5. Deploy the workloads

```bash
gcloud container clusters get-credentials three-tier-app \
  --location us-east1-b --project <your-project-id>

kubectl apply -f yaml-gke/hello-app/deployment.yaml
kubectl apply -k yaml-gke/wordpress
kubectl apply -f yaml-gke/ingress.yaml
```

The load balancer takes about 5 minutes to become healthy:

```bash
kubectl get ingress ingress -w
```

Then, using the address it reports:

| URL | Serves |
|---|---|
| `http://<ingress-ip>/` | WordPress (installer on first visit) |
| `http://<ingress-ip>/hello` | NGINX frontend proxying the Go backend |

Note the `backends` annotation on the Ingress lags reality by a few minutes —
trust an actual HTTP request over an `UNHEALTHY` reading.

### 6. Tear down

Billing runs until you do this.

```bash
kubectl delete -f yaml-gke/ingress.yaml
kubectl delete -k yaml-gke/wordpress
kubectl delete -f yaml-gke/hello-app/deployment.yaml
terraform destroy
```

Delete the Ingress first — it owns a load balancer that Terraform doesn't know
about, and leaving it behind can block the VPC from being deleted. Also check
for orphaned PersistentDisks afterward, since PVC-backed disks are not always
removed automatically.

## Cost

| Item | Approx/month |
|---|---|
| 2 × `e2-medium` nodes | $48 |
| HTTP load balancer | $18 |
| Disks (node boot + 2 × 20 Gi PVC + VM) | $7 |
| `e2-micro` VM | $6 |
| Zonal cluster management fee | covered by GCP free tier |
| **Total** | **~$79** |

Enabling `enable_nat` adds roughly $32/month.

## Hardening

Defaults favour cost and a working first run. For anything longer-lived:

- Set `ssh_source_ranges` to your own `<ip>/32` instead of `0.0.0.0/0`
- Set `control_network` to a specific CIDR instead of `0.0.0.0/0`
- Set `private_nodes = true` **and** `enable_nat = true` together. Enabling
  private nodes alone leaves them with no route to Docker Hub, and the
  WordPress and MySQL pods will sit in `ImagePullBackOff` indefinitely
- Move the MySQL password to Secret Manager
- Give the node pool a dedicated least-privilege service account rather than
  the default Compute Engine one

## CI/CD

`cloudbuild.yaml` runs the whole flow — `terraform init/validate/plan/apply`
followed by the three `kubectl apply` steps. It expects the Cloud Build service
account to hold Kubernetes Engine Admin, Compute Admin, Service Account User,
and Storage Admin.

Running Terraform locally first is recommended; the pipeline applies with
`-auto-approve` and no human review of the plan.

## Known limitations

- **Only one app can own the root.** WordPress takes the default backend, so
  adding a second path-prefixed app that emits absolute URLs would hit the same
  problem WordPress did. Host-based routing is the real answer once more than
  one app needs a root.
- **No TLS.** The ingress serves plain HTTP. Anything real wants a
  ManagedCertificate and an HTTPS redirect.
- **`docker/` is not wired into anything.** The Kubernetes manifests pull public
  images directly and the Cloud Build pipeline never builds this directory. The
  Dockerfiles are kept as a reference for where custom images would go.
- **The backend runs as a DaemonSet**, so it scales with node count rather than
  demand. A Deployment with an HPA would be the conventional choice.
- **MySQL 5.6 is end-of-life.** Fine for a demo, not for anything real.
