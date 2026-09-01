# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package management files
COPY package*.json ./

# Install dependencies cleanly
RUN npm ci

# Copy application source code
COPY . .

# Accept Vite environment variables as build args (overrideable during docker build)
ARG VITE_KEYCLOAK_URL=https://keycloak.pollak.info
ARG VITE_KEYCLOAK_REALM=master
ARG VITE_KEYCLOAK_CLIENT_ID=find

ENV VITE_KEYCLOAK_URL=$VITE_KEYCLOAK_URL
ENV VITE_KEYCLOAK_REALM=$VITE_KEYCLOAK_REALM
ENV VITE_KEYCLOAK_CLIENT_ID=$VITE_KEYCLOAK_CLIENT_ID

# Build production SPA static bundle
RUN npm run build

# Serve stage with Nginx
FROM nginx:alpine AS runner

# Remove default nginx web assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built dist files from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
