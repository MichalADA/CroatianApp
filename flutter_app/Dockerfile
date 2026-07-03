# ─── Stage 1: build Flutter web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG API_BASE_URL=http://localhost:8000
ENV API_BASE_URL=$API_BASE_URL

WORKDIR /app

# Kopiuj pubspec pierwsze — cache warstwy Docker gdy zmienia się tylko kod
COPY pubspec.yaml ./
# Uwaga: pubspec.lock jest w .gitignore, więc kopiujemy tylko jak istnieje
COPY pubspec.lock* ./
RUN flutter pub get

# Kopiuj resztę i buduj
COPY . .

# Codegen (freezed, json_serializable) — obowiązkowe przed compile
RUN dart run build_runner build --delete-conflicting-outputs

# Build produkcyjny weba z compile-time API_BASE_URL
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --no-tree-shake-icons

# ─── Stage 2: serve przez nginx ──────────────────────────────────────────────
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
