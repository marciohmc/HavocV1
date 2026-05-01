# Build Stage
FROM golang:1.22-alpine AS builder

# Instalar todas as dependências de compilação
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

# Copia tudo primeiro para garantir a estrutura
COPY . .

# --- RESILIÊNCIA PARA go.mod ---
# Verifica se o go.mod está na raiz ou na pasta teamserver
RUN if [ -f "./go.mod" ]; then \
        go mod download; \
    elif [ -f "./teamserver/go.mod" ]; then \
        cd teamserver && go mod download; \
    else \
        echo "ERRO: go.mod nao encontrado em /app ou /app/teamserver" && exit 1; \
    fi

# Compilar o binário (decidindo o caminho automaticamente)
RUN if [ -f "./main.go" ]; then \
        go build -ldflags="-s -w" -o /app/havoc-teamserver main.go; \
    elif [ -f "./teamserver/main.go" ]; then \
        cd teamserver && go build -ldflags="-s -w" -o /app/havoc-teamserver main.go; \
    else \
        echo "ERRO: main.go nao encontrado!" && exit 1; \
    fi

# Runtime Stage
FROM alpine:latest
RUN apk add --no-cache python3 py3-pip bash openssl lua5.4

WORKDIR /app

# Copia apenas o necessário do builder
COPY --from=builder /app/havoc-teamserver .
COPY --from=builder /app/data ./data
COPY --from=builder /app/profiles ./profiles

# Variáveis de Ambiente para instâncias de 512MB
ENV GOMEMLIMIT=450MiB
ENV GOGC=40
ENV MALLOC_ARENA_MAX=1

EXPOSE 40056

CMD ["./havoc-teamserver", "server", "--profile", "./profiles/havoc.yaotl", "-v"]
