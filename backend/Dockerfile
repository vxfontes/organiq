FROM golang:1.25-alpine AS dev

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata
RUN go install github.com/air-verse/air@latest

COPY go.mod go.sum ./
RUN go mod download

COPY . ./

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]

FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates tzdata

COPY go.mod go.sum ./
RUN go mod download

COPY . ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/api ./cmd/api

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /app/api /app/api

EXPOSE 8080

CMD ["/app/api"]
