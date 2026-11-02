# Notely

[![CI](https://github.com/Jiyanson/cicd-typescript/actions/workflows/ci.yml/badge.svg)](https://github.com/Jiyanson/cicd-typescript/actions/workflows/ci.yml)

This repository contains the Notely TypeScript application and the automation
used to test, package, and publish it.

## Project structure

```text
.
├── app/                    # TypeScript application and Node configuration
│   ├── public/             # Static browser assets
│   ├── src/                # API and database implementation
│   ├── tests/              # Tests excluded from production compilation
│   ├── package.json
│   └── tsconfig.json
├── devops/
│   ├── ansible/            # Provisioning and bootstrap automation
│   ├── docker/             # Container build definition
│   ├── helm/               # Kubernetes application packaging
│   ├── scripts/            # Local automation helpers
│   ├── terraform/          # Infrastructure as code
│   └── README.md           # Build and delivery documentation
└── .github/workflows/      # GitHub Actions CI/CD workflows
```

GitHub requires workflow files to remain in `.github/workflows`, so they stay
at the repository root even though they are part of the DevOps setup.

See [`app/README.md`](app/README.md) for application details and
[`devops/README.md`](devops/README.md) for build and delivery details.

## Local Development

Make sure you have Node.js 22 or newer, then work from the application
directory:

```bash
cd app
npm install
```

Create `app/.env` from the provided template:

```bash
cp .env.example .env
```

Run the server:

```bash
npm run dev
```

This starts the server in non-database mode and serves the application at
`http://localhost:8080`.

## Quality checks

Run these commands from `app/`:

```bash
npm test
npm run build
npm run lint -- --max-warnings=0
npm run format:check
```

## Container image

Build the image from the repository root so Docker can use `app/` as its build
context:

```bash
docker build --file devops/docker/Dockerfile --tag notely:latest app
```

The same command can be used by a future delivery workflow to publish images to
GitHub Container Registry.
