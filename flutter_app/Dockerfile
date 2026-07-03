# ─── Stage 1: build Flutter web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG API_BASE_URL=http://localhost:8000
ENV API_BASE_URL=$API_BASE_URL

# Flutter wymaga zapisu do SDK żeby stworzyć platform folders — daj mu prawa.
RUN git config --global --add safe.directory /sdks/flutter || true

WORKDIR /app

# Kopiuj pubspec i pobierz zależności (cache warstwy jak zmienia się tylko kod)
COPY pubspec.yaml ./
COPY pubspec.lock* ./

# Kopiuj resztę kodu
COPY . .

# `flutter create` regeneruje brakujące platform folders (web/, android/, ios/).
# Na istniejącym projekcie NIE nadpisuje pubspec.yaml, lib/, ani test/.
# To rozwiązuje problem "web/index.html not found" przy pierwszym buildzie w Dockerze.
RUN flutter create --platforms=web --project-name memory_palace --org com.memorypalace . || true

# Pub get + codegen (freezed / json_serializable)
RUN flutter pub get
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
