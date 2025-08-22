
# 📦 Obsidian LiveSync CouchDB Docker Image

Run [Obsidian Self-Hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) inside Docker with automatic SSL support.  
Designed for **LAN environments** and **mobile devices** that require TLS.  

👉 Supports both **IP** and **DNS-based** setups.  
👉 Works seamlessly **behind reverse proxies** (e.g., Nginx + Let's Encrypt) for WAN/public deployments.

---

## 📂 Project Structure

.  
├── build.env # SSL Common Name (CN) configuration  
├── Dockerfile # Docker image build instructions  
└── scripts/  
├── entrypoint.sh # Container startup: CouchDB + SSL setup  
├── get-rootCA.sh # Extract Root CA certs from container  
├── openssl-dns.cnf # OpenSSL config for DNS CN  
└── openssl-ip.cnf # OpenSSL config for IP CN

---

## 🛠️ Build Instructions

1. Clone the repository:

   git clone https://your_repo_url_here
   cd obsidian-livesync

2. Edit `build.env`:
    
    - `CN_DNS` → FQDN (for domain-based access)
        
    - `CN_IP` → IP address (for direct IP access)
        
3. Build the image:
    
    docker build -t obsidian-livesync .

---

## 🚀 Run Instructions

Start the container with CouchDB credentials and SSL CN:

docker run -d --name obsidian-livesync \
  -p 5984:5984 -p 6984:6984 \
  -e COUCHDB_USER=admin \
  -e COUCHDB_PASSWORD=password123 \
  -e COUCHDB_CN=domain.example \
  obsidian-livesync:latest

- `COUCHDB_USER` → CouchDB admin username
    
- `COUCHDB_PASSWORD` → CouchDB admin password
    
- `COUCHDB_CN` → IP or FQDN for SSL certificate generation
    
---

## ✅ Verification

Check logs:

docker logs obsidian-livesync


Test CouchDB endpoints:

curl -u admin:password123 http://localhost:5984/_all_dbs
curl -u admin:password123 https://localhost:6984/_all_dbs

---

## 🔗 Using with Obsidian LiveSync Plugin

1. Extract Root CA certificates:
    
    bash scripts/get-rootCA.sh obsidian-livesync
    
    This generates `livesync-rootCA.tar.gz` containing:
    
    - **PEM** → Windows
        
    - **DER** → Apple devices
        
    - **CRT** → Android
        
2. Import the certs into your device’s trusted store.
    
3. Configure LiveSync plugin → Server address, port, and credentials.
    
4. Test the connection (should work with TLS).
    
---

## ⚙️ Internal Logic

- Built on **Debian 12 + CouchDB**
    
- SSL Root CA created at build, runtime certs generated on start
    
- Smart CN detection (IP vs DNS)
    
- Entrypoint handles CouchDB init + SSL config
    
- Root CA & certs available via **volume mounts**
    
---

## 📜 License

MIT — use freely for personal or commercial projects.

