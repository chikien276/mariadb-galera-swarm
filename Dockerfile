FROM golang AS stage

ENV CGO_ENABLED=0
ENV GOOS=linux
RUN mkdir -p /build
WORKDIR /build
ADD ./healthcheck .
RUN go get github.com/onsi/ginkgo/ginkgo
RUN go get github.com/sttts/galera-healthcheck/healthcheck
RUN go get github.com/sttts/galera-healthcheck/logger
RUN go get github.com/go-sql-driver/mysql
RUN go build -o galera-healthcheck

FROM mariadb:10.3

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
      curl \
      pigz \
      percona-toolkit \
      pv \
    && curl -sSL -o /tmp/qpress.tar http://www.quicklz.com/qpress-11-linux-x64.tar \
    && tar -C /usr/local/bin -xf /tmp/qpress.tar qpress \
    && chmod +x /usr/local/bin/qpress \
    && rm -rf /tmp/* /var/cache/apk/* /var/lib/apt/lists/*

COPY conf.d/*                /etc/mysql/conf.d/
COPY *.sh                    /usr/local/bin/
COPY --from=stage /build/galera-healthcheck  /usr/local/bin/galera-healthcheck
COPY primary-component.sql   /

# Fix permissions
RUN chown -R mysql:mysql /etc/mysql && chmod -R go-w /etc/mysql

EXPOSE 3306 4444 4567 4567/udp 4568 8080 8081

HEALTHCHECK CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["start.sh"]
