########################################################################################
# Build
########################################################################################

# Source: adapted from gaia-daemon in this project

FROM golang:1.22-alpine AS build

WORKDIR /app
COPY version /version

ENV PACKAGES="curl make git libc-dev bash file gcc linux-headers eudev-dev python3"
RUN apk add --no-cache $PACKAGES

ARG SRC_COMMIT=b973bffdf127866f45624d7e5a81f31fdc8e8e0b
RUN VERSION="$(sed 's/-.*//' /version)" && \
  git init && \
  git remote add origin https://github.com/osmosis-labs/osmosis && \
  git fetch --depth 1 origin "v${VERSION}" && \
  git checkout $SRC_COMMIT

# See https://github.com/CosmWasm/wasmvm/releases
ARG WASMVM_VERSION=v1.5.2
ADD https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep e78b224c15964817a3b75a40e59882b4d0e06fd055b39514d61646689cef8c6e
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep e660a38efb2930b34ee6f6b0bb12730adccb040b6ab701b8f82f34453a426ae7
RUN cp "/lib/libwasmvm_muslc.x86_64.a" /lib/libwasmvm_muslc.a

# build
RUN go mod download
#RUN LEDGER_ENABLED=true LINK_STATICALLY=true BUILD_TAGS=muslc make build

# Build osmosisd binary
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/go/pkg/mod \
    GOWORK=off go build \
    -mod=readonly \
    -tags "netgo,ledger,muslc" \
    -ldflags \
    "-X github.com/cosmos/cosmos-sdk/version.Name="osmosis" \
    -X github.com/cosmos/cosmos-sdk/version.AppName="osmosisd" \
    -X github.com/cosmos/cosmos-sdk/version.Version=${GIT_VERSION} \
    -X github.com/cosmos/cosmos-sdk/version.Commit=${GIT_COMMIT} \
    -X github.com/cosmos/cosmos-sdk/version.BuildTags=${BUILD_TAGS} \
    -w -s -linkmode=external -extldflags '-Wl,-z,muldefs -static'" \
    -trimpath \
    -o /app/build/osmosisd \
    /app/cmd/osmosisd/main.go

RUN echo "Ensuring binary is statically linked ..."  \
  && file /app/build/osmosisd | grep "statically linked"

########################################################################################
# Deploy
########################################################################################

FROM alpine:3.20
RUN apk add --no-cache curl jq
COPY --from=build /app/build/osmosisd /osmosisd
COPY entrypoint.sh /entrypoint.sh
COPY app.toml /etc/osmosis/app.toml
CMD ["/entrypoint.sh"]
