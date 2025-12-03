# Use official Node.js LTS image
FROM node:20-alpine as base

# Set working directory
WORKDIR /app

# Install dependencies only, then copy source for smaller layers
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./

# Install dependencies (use npm ci for reproducible builds)
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; \
    elif [ -f pnpm-lock.yaml ]; then npm install -g pnpm && pnpm install --frozen-lockfile --prod; \
    elif [ -f yarn.lock ]; then yarn install --production; \
    else npm install --omit=dev; fi

# Copy all source files
COPY . .

# Build the app (if using SvelteKit, this will output to .svelte-kit or build)
RUN npm run build

# Production image, copy only necessary files
FROM node:20-alpine as prod
WORKDIR /app

# Copy node_modules and built app from previous stage
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/build ./build
COPY --from=base /app/package.json ./
COPY --from=base /app/.env.local ./

# Expose port (default 3000)
EXPOSE 3000

# Set NODE_ENV to production
ENV NODE_ENV=production

# Start the app
CMD ["npm", "start"]
