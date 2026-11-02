# DevOps Project Plan: GitOps Platform for the TypeScript API

Goal: a reproducible pipeline from `git push` to a running app on Kubernetes,
with Terraform, Ansible, Helm, Argo CD, and monitoring.

## How the pieces fit

| Part | Job | Tool |
|---|---|---|
| CI | Test, lint, scan, build the image, push to GHCR, update the image tag in git | GitHub Actions |
| CD | Make the cluster match what is in git | Argo CD |

Argo CD is the only thing that deploys. CI never runs `kubectl` or `helm upgrade`.
CI only builds the image and commits the new tag into `values-dev.yaml`.
Argo CD sees that commit and syncs the cluster.

---

## Phase 0: Setup and baseline

- [ ] 0.1 Create the repo structure: `app/`, `helm/`, `terraform/`, `ansible/`, `docs/`
- [ ] 0.2 Confirm the TypeScript API runs locally (`npm install`, `npm start`)
- [ ] 0.3 Add a `Dockerfile` (multi-stage, non-root user, `node:lts-alpine`)
- [ ] 0.4 Confirm the image builds locally: `docker build -t cicd-typescript .`
- [ ] 0.5 Add a `README.md` with a one-paragraph project description

## Phase 1: Continuous Integration

- [ ] 1.1 Add unit tests (Vitest or Jest) with at least 3 tests
- [ ] 1.2 Add ESLint and a `lint` script in `package.json`
- [ ] 1.3 Create `.github/workflows/ci.yml` on `pull_request`: install, lint, test
- [ ] 1.4 Add a Trivy image scan that fails on CRITICAL vulnerabilities
- [ ] 1.5 Pin all actions to commit SHAs instead of tags
- [ ] 1.6 Enable branch protection on `main`: require a PR and the CI check
- [ ] 1.7 Fix the image build step: lowercase the image name, push to GHCR
- [ ] 1.8 Confirm a PR cannot merge while CI is failing (test it on purpose)

## Phase 2: Helm chart

- [ ] 2.1 Create `helm/cicd-typescript/` with `helm create`, then remove the defaults you don't need
- [ ] 2.2 Template a Deployment with probes (`/healthz` or similar) and resource limits
- [ ] 2.3 Template a Service and an Ingress (document it if you skip the Ingress in kind)
- [ ] 2.4 Add an HPA template, enabled only in staging
- [ ] 2.5 Create `values-dev.yaml` and `values-staging.yaml`, with the image tag in both
- [ ] 2.6 Run `helm lint` and `helm template` locally, and read the output
- [ ] 2.7 Add `helm lint` to CI

## Phase 3: Local Kubernetes cluster

- [ ] 3.1 Install Docker, kubectl, kind, and Helm on your machine
- [ ] 3.2 Create a kind cluster with a config file that maps port 80
- [ ] 3.3 Install the app once by hand with `helm install` to confirm the chart works
- [ ] 3.4 Confirm the app responds through the port mapping
- [ ] 3.5 Write `docs/decisions.md`: why kind, why Helm, why GHCR, why Argo CD

## Phase 4: Argo CD (GitOps deployment)

- [ ] 4.1 Install Argo CD in the cluster (`kubectl create namespace argocd`, then apply the manifest)
- [ ] 4.2 Log in to the Argo CD UI and change the admin password
- [ ] 4.3 Uninstall the manual Helm release from 3.3, so Argo CD owns the app
- [ ] 4.4 Create an Argo CD `Application` for dev that points at `helm/cicd-typescript` in your repo
- [ ] 4.5 Enable automated sync with self-heal and prune for dev
- [ ] 4.6 Create a second Application for staging with manual sync
- [ ] 4.7 Add a CI step that sets the new image tag in `values-dev.yaml` and commits it (see below)
- [ ] 4.8 Push a change, then confirm Argo CD syncs the new image tag
- [ ] 4.9 Take a screenshot of the Argo CD app tree for the README

### Step 4.7 details

The CI workflow, after the image is pushed, runs:

    yq -i '.image.tag = "'"$GITHUB_SHA"'"' helm/cicd-typescript/values-dev.yaml
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git commit -am "deploy: dev image ${GITHUB_SHA}"
    git push

The job needs `permissions: contents: write`. Commits made with `GITHUB_TOKEN`
do not trigger other workflows, which is what you want here.

## Phase 5: Terraform

- [ ] 5.1 Install Terraform and run `terraform init` in `terraform/`
- [ ] 5.2 Add the GitHub provider and manage branch protection with it
- [ ] 5.3 Create an S3 bucket for remote state (if your AWS account allows it)
- [ ] 5.4 Configure remote state in `backend.tf`
- [ ] 5.5 Split variables into `dev.tfvars` and `staging.tfvars`
- [ ] 5.6 Add `terraform fmt -check` and `terraform validate` to CI
- [ ] 5.7 Add a `terraform plan` job on pull requests

## Phase 6: Ansible

- [ ] 6.1 Set up an Ubuntu VM (Multipass or VirtualBox)
- [ ] 6.2 Create `ansible/inventory.ini` and confirm `ansible all -m ping` works
- [ ] 6.3 Write a `docker` role that installs Docker
- [ ] 6.4 Write a `kubernetes-tools` role that installs kubectl, kind, and Helm
- [ ] 6.5 Write an `argocd` role that creates the cluster and installs Argo CD
- [ ] 6.6 Run `ansible-playbook site.yml` on a fresh VM and confirm it works end to end
- [ ] 6.7 Add `ansible-lint` to CI

## Phase 7: Monitoring

- [ ] 7.1 Add a `/metrics` endpoint to the API with `prom-client`
- [ ] 7.2 Install `kube-prometheus-stack` with Helm (managed by Argo CD)
- [ ] 7.3 Add a ServiceMonitor for the API
- [ ] 7.4 Build a Grafana dashboard: request rate, error rate, latency
- [ ] 7.5 Take a screenshot for the README

## Phase 8: Security

- [ ] 8.1 Store secrets with Sealed Secrets (or External Secrets), not plain Secrets in git
- [ ] 8.2 Add a NetworkPolicy so only the ingress controller reaches the API
- [ ] 8.3 Set `securityContext`: non-root, read-only root filesystem, drop all capabilities
- [ ] 8.4 Delete the `github_actions_deployer` IAM user and its access key

## Phase 9: Documentation and portfolio

- [ ] 9.1 Finish the README: architecture diagram, setup steps, screenshots
- [ ] 9.2 Add a short French summary to the README
- [ ] 9.3 Tag a release (`v1.0.0`) with a changelog
- [ ] 9.4 Write a LinkedIn post about what you built and learned
- [ ] 9.5 Add the project and 3 resume bullets to your CV

---

## Progress log

Date | Task | Notes
---- | ---- | -----