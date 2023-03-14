# Use latest stable channel SDK.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN dart pub get
RUN dart compile exe bin/pvpc_server.dart -o bin/pvpc_server

# Build minimal serving image from AOT-compiled `/pvpc_server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM debian:bullseye-slim
COPY --from=build /runtime/ /
COPY --from=build /app/bin/pvpc_server /app/bin/
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Start pvpc_server.
CMD ["/app/bin/pvpc_server"]
