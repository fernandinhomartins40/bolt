FROM node:20-alpine AS base

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apk add --no-cache libc6-compat python3 make g++

# Enable corepack and install pnpm
RUN corepack enable pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies with increased memory and timeout
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy the rest of your app's source code
COPY . .

# Expose the port the app runs on
EXPOSE 3050

# Production image
FROM base AS bolt-ai-production

# Set basic environment variables (non-sensitive)
ENV WRANGLER_SEND_METRICS=false \
    NODE_ENV=production \
    VITE_LOG_LEVEL=info \
    DEFAULT_NUM_CTX=32768 \
    RUNNING_IN_DOCKER=true

# Pre-configure wrangler to disable metrics
RUN mkdir -p /root/.config/.wrangler && \
    echo '{"enabled":false}' > /root/.config/.wrangler/metrics.json

# Build with increased memory limit
RUN NODE_OPTIONS="--max-old-space-size=4096" pnpm run build

CMD [ "pnpm", "run", "dockerstart", "--", "--port", "3050"]

# Development image
FROM base AS bolt-ai-development

# Set development environment variables (non-sensitive)
ENV NODE_ENV=development \
    VITE_LOG_LEVEL=debug \
    DEFAULT_NUM_CTX=32768 \
    RUNNING_IN_DOCKER=true

RUN mkdir -p /app/run
CMD pnpm run dev --host
