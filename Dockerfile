FROM debian:bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    wget \
    ca-certificates \
    openjdk-17-jdk-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O /tmp/cmdline-tools.zip \
    && mkdir -p $ANDROID_HOME/cmdline-tools \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 \
    && $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0" \
        "ndk;27.0.12077973" \
    && rm -rf $ANDROID_HOME/.android/cache

RUN git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && flutter precache --android \
    && flutter config --android-sdk $ANDROID_HOME \
    && yes | flutter doctor --android-licenses > /dev/null 2>&1

RUN dart --disable-analytics

WORKDIR /app

FROM base AS deps
COPY pubspec.yaml pubspec.lock* /app/
RUN flutter pub get

FROM deps AS build
COPY . /app/
RUN flutter pub get

FROM build AS debug
RUN flutter build apk --debug --output=dist/app-debug.apk

FROM build AS release
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
