FROM debian:bookworm

ARG COUCHDB_USER=admin
ARG COUCHDB_PASSWORD=password

# couchdb 
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl apt-transport-https gnupg ca-certificates tini jq wget openssl iproute2 \
    && curl -fsSL https://couchdb.apache.org/repo/keys.asc | gpg --dearmor -o /usr/share/keyrings/couchdb-archive-keyring.gpg \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/couchdb.list \
    && echo "couchdb couchdb/cookie string mysecretcookie" | debconf-set-selections \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --fix-missing couchdb \
    && rm -rf /var/lib/apt/lists/* && apt-get clean

RUN mkdir -p /opt/couchdb/init /opt/couchdb/etc/ssl /certs /ca \
    && chown -R couchdb:couchdb /opt/couchdb/init /opt/couchdb/etc/ssl /certs /ca

# CA
RUN openssl req -x509 -new -nodes -days 3650 -newkey rsa:4096 \
      -keyout /opt/couchdb/etc/ssl/rootCA.key \
      -out /opt/couchdb/etc/ssl/rootCA.crt \
      -subj "/CN=Livesync-CouchDB-CA" \
      -sha256 \
    && cp /opt/couchdb/etc/ssl/rootCA.crt /ca/rootCA.crt

RUN chmod 640 /opt/couchdb/etc/ssl/rootCA.key && chown couchdb:couchdb /opt/couchdb/etc/ssl/rootCA.key

# livesync init 
RUN wget -O /opt/couchdb/init/couchdb-init.sh https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh \
    && chmod +x /opt/couchdb/init/couchdb-init.sh \
    && chown -R couchdb:couchdb /opt/couchdb/init

# entrypoint 
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && chown couchdb:couchdb /usr/local/bin/entrypoint.sh

# openssl
COPY build.env /tmp/build.env

COPY scripts/openssl-ip.cnf /opt/couchdb/etc/ssl/openssl-ip.cnf
COPY scripts/openssl-dns.cnf /opt/couchdb/etc/ssl/openssl-dns.cnf

# build vars 
RUN . /tmp/build.env && \
    sed -i "s/__CN_DNS__/${CN_DNS}/g" /opt/couchdb/etc/ssl/openssl-dns.cnf && \
    sed -i "s/__CN_IP__/${CN_IP}/g" /opt/couchdb/etc/ssl/openssl-ip.cnf && \
    chown couchdb:couchdb /opt/couchdb/etc/ssl/openssl-*.cnf && \
    rm /tmp/build.env

#  default CouchDB conf
RUN echo -e "\n[chttpd]\nbind_address = 0.0.0.0\n\n[ssl]\nenable = false" >> /opt/couchdb/etc/local.ini

# certs 
VOLUME ["/opt/couchdb/data"]
VOLUME ["/ca"]

# ports
EXPOSE 5984 6984

# user
USER couchdb
ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
