# Multi-stage production build for Node/Express Failure Lab App
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./
RUN npm ci

# Copy Prisma schema and generate client
COPY src/prisma ./src/prisma
RUN npx prisma generate

# Copy project files and build
COPY . .
RUN npx nx build api --configuration=production

# Production runtime stage
FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Install production dependencies only
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy generated Prisma client from builder
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/src/prisma ./src/prisma

# Copy built app dist
COPY --from=builder /app/dist/api ./dist/api

EXPOSE 3000

CMD ["node", "dist/api/main.js"]
