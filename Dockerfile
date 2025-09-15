FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    gnupg \
    build-essential \
    libicu-dev \
    libssl-dev \
    libyaml-dev \
    libreadline-dev \
    zlib1g-dev \
    git \
    jq \
    locales \
    openjdk-17-jdk \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

# Install Ruby
ARG RUBY_VERSION="3.3.4"
RUN curl -fsSL https://cache.ruby-lang.org/pub/ruby/3.3/ruby-${RUBY_VERSION}.tar.gz -o ruby.tar.gz && \
    tar -xzf ruby.tar.gz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure && make && make install && \
    cd .. && rm -rf ruby-${RUBY_VERSION} ruby.tar.gz
RUN ruby -v

# Install NodeJS
ARG NODE_VERSION="20.19.3"
ARG NPM_VERSION="10.8.2"
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz"
RUN npm install -g npm@"$NPM_VERSION"
RUN node -v
RUN npm -v

# Install Android
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

ARG ANDROID_SDK_VERSION=13114758
ARG ANDROID_BUILD_TOOLS_VERSION=35.0.0
ARG ANDROID_NDK_VERSION=27.1.12297006
ARG ANDROID_PLATFORM_VERSION=35
ARG CMAKE_VERSION=3.22.1

ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK=${ANDROID_HOME}

ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV PATH="${PATH}:${ANDROID_HOME}/tools/bin"
ENV PATH="${PATH}:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}"
ENV PATH="${PATH}:${ANDROID_HOME}/platform-tools"
ENV PATH="${PATH}:${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}"
ENV PATH="${PATH}:${ANDROID_HOME}/emulator"

# download and install Android SDK
RUN mkdir -p $ANDROID_HOME && cd $ANDROID_HOME && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip *commandlinetools*linux*.zip -d cmdline-tools/ && \
    rm *commandlinetools*linux*.zip && \
    mv cmdline-tools/cmdline-tools/ cmdline-tools/latest/ && \
    yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platforms;android-${ANDROID_PLATFORM_VERSION}"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-${ANDROID_PLATFORM_VERSION};google_apis_playstore;x86_64"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;${ANDROID_NDK_VERSION}"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "cmake;${CMAKE_VERSION}"

RUN mkdir /app
WORKDIR /app

# Install bundler and dependencies
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV BUNDLE_PATH="/app/vendor/bundle"
ENV BUNDLE_CACHE_PATH="/app/vendor/cache"
ENV PATH="/usr/local/bundle/bin:$PATH"
ARG BUNDLER_VERSION="2.4.19"
RUN gem install bundler:$BUNDLER_VERSION

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle update ffi
RUN bundle config set path $BUNDLE_PATH
RUN bundle install --binstubs --system --no-cache