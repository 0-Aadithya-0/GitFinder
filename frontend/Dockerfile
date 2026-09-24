# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# BACKEND_URL is baked in at compile time via --dart-define.
# String.fromEnvironment() is a compile-time constant and cannot be
# injected at container runtime — it must be set here.
ARG BACKEND_URL=http://localhost:8000
RUN flutter build web --release --dart-define=BACKEND_URL=$BACKEND_URL

# ── Stage 2: Serve ───────────────────────────────────────────────────────────
FROM nginx:alpine

# Custom nginx config to support Flutter's client-side routing (go_router).
# Without try_files, any direct URL other than "/" returns a 404.
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
