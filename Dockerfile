FROM node:20-slim AS base

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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

# Build with increased memory limit and skip workerd by removing problematic package
RUN rm -rf node_modules/.pnpm/@cloudflare+workerd-linux-64@*/node_modules/@cloudflare/workerd-linux-64/bin/workerd || true
RUN NODE_OPTIONS="--max-old-space-size=4096" CI=true pnpm run build

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
