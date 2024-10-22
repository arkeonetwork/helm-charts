########################################################################################
# Build
########################################################################################

# Source: adapted from gaia-daemon in this project

FROM golang:1.22-alpine3.20 AS build

WORKDIR /app
COPY version /version

ENV PACKAGES="curl make git libc-dev bash file gcc linux-headers eudev-dev python3"
RUN apk add --no-cache $PACKAGES

ARG SRC_COMMIT=768fbf7c738b917ee2e0b482feae34575089b089
RUN VERSION="$(sed 's/-.*//' /version)" && \
  git init && \
  git remote add origin https://github.com/osmosis-labs/osmosis && \
  git fetch --depth 1 origin "v${VERSION}" && \
  git checkout $SRC_COMMIT

# See https://github.com/CosmWasm/wasmvm/releases
ARG WASMVM_VERSION=v2.1.2
ADD https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep 0881c5b463e89e229b06370e9e2961aec0a5c636772d5142c68d351564464a66
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep 58e1f6bfa89ee390cb9abc69a5bc126029a497fe09dd399f38a82d0d86fe95ef
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
