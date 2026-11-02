# Notely application

This directory contains the runtime application and its Node.js tooling.

## Layout

```text
app/
├── public/            # Static files served by Express
├── src/
│   ├── api/           # HTTP handlers and middleware
│   ├── database/      # Schema, queries, and migrations
│   ├── config.ts      # Environment-backed configuration
│   └── main.ts        # Application entry point
├── tests/             # Tests kept outside production compilation
├── .env.example       # Local configuration template
└── package.json       # Commands and dependencies
```

## Development

```bash
cp .env.example .env
npm install
npm run dev
```

## Validation

```bash
npm test
npm run build
npm run lint -- --max-warnings=0
npm run format:check
```
