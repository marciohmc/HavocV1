# Build Stage
FROM golang:1.22-alpine AS builder

# Instalar dependências de compilação essenciais
RUN apk add --no-cache git build-base python3-dev pkgconfig

WORKDIR /app

# Copia os arquivos do repo forkado
COPY . .

# Compilar o Teamserver com otimização de tamanho (remover símbolos de debug)
WORKDIR /app/teamserver
RUN go mod download
RUN go build -ldflags="-s -w" -o havoc-teamserver main.go

# Runtime Stage - Usando Alpine para footprint mínimo
FROM alpine:latest
RUN apk add --no-cache python3 py3-pip bash

WORKDIR /app
COPY --from=builder /app/teamserver/havoc-teamserver .
COPY --from=builder /app/data ./data
COPY --from=builder /app/profiles ./profiles

# Otimização Crítica para 512MB RAM (Render Free Instance)
ENV GOMEMLIMIT=450MiB
ENV GOGC=40
ENV MALLOC_ARENA_MAX=1

EXPOSE 40056

# Iniciando com o perfil padrão
CMD ["./havoc-teamserver", "server", "--profile", "./profiles/havoc.yaotl", "-v"]
