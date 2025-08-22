#!/bin/bash
set -e
set -x

: "${COUCHDB_USER:=admin}"
: "${COUCHDB_PASSWORD:=password}"
: "${HOSTNAME_URL:=http://127.0.0.1:5984}"
: "${COUCHDB_CN:=127.0.0.1}"

export username="${COUCHDB_USER}"
export password="${COUCHDB_PASSWORD}"
export hostname="${HOSTNAME_URL}"

echo "Using hostname=${hostname}, username=${username}, CN=${COUCHDB_CN}"

# admin pass
echo -e "[admins]\n${COUCHDB_USER} = ${COUCHDB_PASSWORD}" > /opt/couchdb/etc/local.d/admin.ini

SSL_DIR="/opt/couchdb/etc/ssl"
mkdir -p "$SSL_DIR"
sed -i '/^\[ssl\]/,/^\[/{d}' /opt/couchdb/etc/local.ini

# CN
if [[ "$COUCHDB_CN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    cp "$SSL_DIR/openssl-ip.cnf" "$SSL_DIR/openssl.cnf"
else
    cp "$SSL_DIR/openssl-dns.cnf" "$SSL_DIR/openssl.cnf"
fi

# certs
openssl req -new -nodes -newkey rsa:2048 \
  -keyout "$SSL_DIR/server_key.pem" \
  -out "$SSL_DIR/server.csr" \
  -config "$SSL_DIR/openssl.cnf"

openssl x509 -req -in "$SSL_DIR/server.csr" \
  -CA "$SSL_DIR/rootCA.crt" -CAkey "$SSL_DIR/rootCA.key" -CAcreateserial \
  -out "$SSL_DIR/server_cert.pem" -days 365 -sha256 \
  -extfile "$SSL_DIR/openssl.cnf" -extensions v3_req

cp "$SSL_DIR/rootCA.crt" /certs/rootCA.crt
cp "$SSL_DIR/server_cert.pem" /certs/server_cert.pem
cp "$SSL_DIR/rootCA.crt" /certs/rootCA_Win.crt
openssl x509 -in "$SSL_DIR/rootCA.crt" -outform der -out /certs/rootCA_Apple.der
cp "$SSL_DIR/rootCA.crt" /certs/rootCA_Android.crt

# TLS
cat <<EOF >> /opt/couchdb/etc/local.ini
[ssl]
enable = true
port = 6984
cert_file = $SSL_DIR/server_cert.pem
key_file = $SSL_DIR/server_key.pem
bind_address = 0.0.0.0
EOF

sed -i '/^\[chttpd\]/a bind_address = 0.0.0.0\nport = 5984' /opt/couchdb/etc/local.ini

#  couchdb start
/opt/couchdb/bin/couchdb &
echo "Waiting for CouchDB to be ready..."
until curl -s -u "${username}:${password}" "${hostname}/" >/dev/null; do
    sleep 2
done
echo "CouchDB is up."

# livesync init
INIT_SCRIPT="/opt/couchdb/init/couchdb-init.sh"
NODE_NAME=$(curl -s -u "${username}:${password}" "${hostname}/_membership" | jq -r '.all_nodes[0]')
sed -i "s/nonode@nohost/${NODE_NAME}/g" "${INIT_SCRIPT}"
bash "${INIT_SCRIPT}" || echo "Init script failed or already applied"

wait
