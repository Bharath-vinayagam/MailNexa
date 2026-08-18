# ─── Build Stage ──────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies only (layer cache optimization)
COPY package*.json ./
RUN npm ci --only=production

# ─── Production Stage ─────────────────────────────────────
FROM node:20-alpine AS production

# Security: run as non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S mailguard -u 1001

WORKDIR /app

# Copy production node_modules from builder
COPY --from=builder --chown=mailguard:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=mailguard:nodejs . .

# Create logs directory with correct permissions
RUN mkdir -p logs && chown mailguard:nodejs logs

# Switch to non-root user
USER mailguard

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

# Start server
CMD ["node", "server.js"]
