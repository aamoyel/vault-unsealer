# Build image
FROM golang:1.18-alpine3.15 AS builder
ENV APP_DIR=/src \
    USER=app \
    UID=10001
WORKDIR ${APP_DIR}
COPY . ${APP_DIR}

# Add app user, fetch dependencies and build binary
RUN adduser --disabled-password --gecos "" --home "/nonexistent" --shell "/sbin/nologin" --no-create-home --uid "${UID}" "${USER}" && \
    go get -d -v && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOAMD64=v3 go build -ldflags="-w -s" -o ${APP_DIR}/app *.go

# Final image
FROM scratch
LABEL MAINTAINER Author <alan.amoyel@epsi.fr>
ENV APP_DIR=/src

# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Import binary
COPY --from=builder ${APP_DIR} ${APP_DIR}

# Use an unprivileged user.
USER app:app

WORKDIR ${APP_DIR}
CMD [ "./app" ]