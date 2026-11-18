FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download || true

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/server .

ENV PORT=8080
EXPOSE 8080

CMD ["./server"]
