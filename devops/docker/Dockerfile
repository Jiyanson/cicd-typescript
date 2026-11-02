FROM node:22-slim AS build

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-slim AS production

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /usr/src/app/dist ./dist
COPY public ./public

EXPOSE 8080

CMD ["node", "dist/main.js"]
