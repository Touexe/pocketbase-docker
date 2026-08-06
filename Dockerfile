FROM alpine:3.24.1 AS sqlean-downloader
RUN apk add --no-cache wget unzip
RUN wget https://github.com/nalgeon/sqlean/releases/download/0.28.3/sqlean-linux-x64.zip \
    && unzip sqlean-linux-x64.zip -d /sqlean

FROM golang:1.25-bookworm AS builder
WORKDIR /build
COPY main.go .
RUN go mod init pocketbase-custom \
    && go mod tidy \
    && CGO_ENABLED=1 go build -o pocketbase .

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata wget procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/pocketbase /usr/local/bin/pocketbase
COPY --from=sqlean-downloader /sqlean/fileio.so /usr/lib/fileio.so
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
