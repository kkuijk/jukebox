
# Production image met Node + Supervisor om meerdere processen te runnen
FROM node:20-alpine

# Basis tools
RUN apk add --no-cache bash curl supervisor

# Gebruik Yarn via Corepack (zit bij Node 20)
RUN corepack enable

# Werkmap
WORKDIR /app

# Eerst dependency-manifests kopiëren voor betere caching
# (root heeft geen package.json; wel in server/ en frontend/)
COPY server/package.json server/yarn.lock* server/
COPY frontend/package.json frontend/yarn.lock* frontend/

# Dependencies installeren (server)
WORKDIR /app/server
RUN yarn install --frozen-lockfile || yarn install

# Dependencies installeren (frontend)
WORKDIR /app/frontend
RUN yarn install --frozen-lockfile || yarn install

# Nu alle broncode kopiëren
WORKDIR /app
COPY server server
COPY frontend frontend
COPY supervisord.conf /etc/supervisord.conf

# Frontend build (Next.js)
WORKDIR /app/frontend
RUN yarn build

# Server build (TypeScript → JS), als het script bestaat; anders negeren
WORKDIR /app/server
RUN yarn build || true

# Standaardpoort voor frontend
ENV PORT=3000
# Frontend moet de backend kunnen aanroepen binnen dezelfde container:
ENV NEXT_PUBLIC_API_BASE_URL="http://localhost:3001"

# Expose alleen frontend-poort; backend is intern bereikbaar
EXPOSE 3000

# Start alle processen# Start alle processen via Supervisor
