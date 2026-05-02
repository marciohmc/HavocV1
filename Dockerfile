# Build Stage
FROM golang:1.22-alpine AS builder

# Instalar dependências de compilação essenciais (CGO + Python)
RUN apk add --no-cache \
    git \
    build-base \
    python3-dev \
    pkgconfig \
    openssl-dev \
    libffi-dev \
    bash \
    lua5.4-dev


WORKDIR /app

# 1. Clonar o repositório OFICIAL do Havoc
RUN git clone https://github.com/HavocFramework/Havoc.git .

# 2. Compilar o Teamserver
RUN cd teamserver && go mod download && \
    go build -ldflags="-s -w -X 'github.com/HavocFramework/Havoc/teamserver/cmd.VersionCommit=$(git rev-parse HEAD)'" -o /app/havoc-teamserver main.go

# 3. Baixar Compiladores Cross (conforme script oficial)
RUN mkdir -p data && \
    wget https://musl.cc/x86_64-w64-mingw32-cross.tgz -q -O /tmp/mingw-64.tgz && \
    tar xzf /tmp/mingw-64.tgz -C data && \
    wget https://musl.cc/i686-w64-mingw32-cross.tgz -q -O /tmp/mingw-86.tgz && \
    tar xzf /tmp/mingw-86.tgz -C data && \
    rm /tmp/mingw-*.tgz

# Runtime Stage
FROM alpine:latest

# Configurar PATH
ENV PATH="/usr/bin:${PATH}"

# Dependências de runtime essenciais (Incluindo compiladores para o Demon)
RUN apk add --no-cache \
    python3 \
    bash \
    openssl \
    lua5.4 \
    libstdc++ \
    libgcc \
    ca-certificates \
    sqlite-libs \
    gcompat \
    nasm

WORKDIR /app

# Copia TUDO do builder para manter a estrutura (data, profiles, scripts)
COPY --from=builder /app /app

RUN chmod +x ./havoc-teamserver

ENV GOMEMLIMIT=450MiB
EXPOSE 40056

# INICIALIZAÇÃO
CMD ["/bin/sh", "-c", " \
    PROFILE=$(find . -name 'havoc.yaotl' -print -quit); \
    ./havoc-teamserver server --profile \"$PROFILE\" -v \
"]
