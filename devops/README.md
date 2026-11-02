# DevOps

This directory contains infrastructure and local automation that support the
Notely application.

## Docker

The multi-stage Docker build compiles the TypeScript application in one stage
and copies only production dependencies, compiled JavaScript, and public assets
into the runtime image.

Run this command from the repository root:

```bash
docker build --file devops/docker/Dockerfile --tag notely:latest app
```

## Infrastructure areas

- `ansible/` is reserved for machine provisioning, tool installation, and Argo
  CD bootstrap automation.
- `helm/` is reserved for the application chart and environment-specific
  values.
- `terraform/` is reserved for managed infrastructure, repository settings,
  and remote-state configuration.

## Scripts

`scripts/push-changes.sh` stages the working tree, creates a commit, and pushes
the current branch. Pass the commit message as its first argument:

```bash
./devops/scripts/push-changes.sh "Describe the change"
```

## GitHub Actions

GitHub requires workflow definitions under `.github/workflows/`, so CI/CD files
remain there. The current CI workflow validates the application from `app/`.
A future delivery workflow can use the Dockerfile in this directory to publish
the application image.
