FROM node:18.5.0-bullseye as node
FROM node as builder
COPY --from=denoland/deno:1.23.3 /usr/bin/deno /usr/bin/deno
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    clang \
    git \
    openssh-client \
    unzip \
    wget && \
    rm -rf /var/lib/apt/lists/*
COPY . /usr/local/apisix/javascript-plugin-runner
WORKDIR /usr/local/apisix/javascript-plugin-runner
RUN npm install
RUN make build

# APISIX with JavaScript Plugin Runner
FROM apache/apisix:2.13.2-alpine

# Node.js
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# APISIX JavaScript Plugin Runner
COPY --from=builder /usr/local/apisix/javascript-plugin-runner /usr/local/apisix/javascript-plugin-runner
