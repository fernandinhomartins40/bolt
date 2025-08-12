FROM node:20-slim AS base

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    bash \
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

# Create a custom build script that skips problematic workerd
RUN echo '#!/bin/bash\n\
set -e\n\
export NODE_OPTIONS="--max-old-space-size=4096"\n\
export CI=true\n\
export SKIP_WRANGLER=true\n\
export NO_CLOUDFLARE=true\n\
echo "Building without Cloudflare workerd..."\n\
npx remix vite:build --mode production\n\
echo "Build completed successfully!"\n' > /tmp/build.sh && chmod +x /tmp/build.sh

# Run the custom build script
RUN /tmp/build.sh

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
