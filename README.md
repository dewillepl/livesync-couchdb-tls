## 📦 Obsidian LiveSync CouchDB Docker Image

Run [Obsidian Self-Hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) inside Docker with automatic SSL support.  
Designed for **LAN environments** and **mobile devices** that require TLS.

- Supports both **IP** and **DNS-based** setups.  
- Works seamlessly **behind reverse proxies** (e.g., Nginx + Let's Encrypt) for WAN/public deployments.
- Works on Windows with Docker Desktop.

## 📂 Project Structure

```
build.env                # SSL Common Name (CN) configuration
Dockerfile               # Docker image build instructions
scripts/entrypoint.sh    # Container startup: CouchDB + SSL setup
scripts/get-rootCA.sh    # Extract Root CA certs from container
scripts/openssl-dns.cnf  # OpenSSL config for DNS CN
scripts/openssl-ip.cnf   # OpenSSL config for IP CN
```

## 🛠️ Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/dewillepl/livesync-couchdb-tls
   cd livesync-couchdb-tls
   ```

2. Edit `build.env`:  
   - `CN_DNS` → FQDN (for domain-based access)  
   - `CN_IP` → IP address (for direct IP access)  

3. Build the image:
   ```bash
   docker build -t livesync-couchdb-tls .
   ```

## 🚀 Run Instructions

Start the container with CouchDB credentials and SSL CN:

```bash
docker run -d --name livesync-couchdb-tls \
  -p 5984:5984 -p 6984:6984 \
  -e COUCHDB_USER=admin \
  -e COUCHDB_PASSWORD=password123 \
  -e COUCHDB_CN=domain.example \
  livesync-couchdb-tls:latest
```

- `COUCHDB_USER` → CouchDB admin username  
- `COUCHDB_PASSWORD` → CouchDB admin password  
- `COUCHDB_CN` → IP or FQDN for SSL certificate generation  

---

Docker Compose:
```yaml
version: '3'
services:
  livesync-couchdb-tls:
    image: livesync-couchdb-tls:latest
    container_name: livesync-couchdb-tls
    ports:
      - "5984:5984"
      - "6984:6984"
    environment:
      COUCHDB_USER: admin
      COUCHDB_PASSWORD: password123
      COUCHDB_CN: domain.example
```

## ✅ Verification

Check logs:
```bash
docker logs livesync-couchdb-tls
```

Test CouchDB endpoints:
```bash
curl -u admin:password123 http://localhost:5984/_all_dbs
curl -u admin:password123 https://localhost:6984/_all_dbs
```

## 🔗 Using with Obsidian LiveSync Plugin

1. Extract Root CA certificates:
   ```bash
   bash scripts/get-rootCA.sh livesync-couchdb-tls
   ```

   This creates a CA folder with individual certificates (PEM, DER, CRT) and generates "livesync-rootCA.tar.gz" containing them for Windows, Apple devices, and Android.
   - **PEM** → Windows  
   - **DER** → Apple devices  
   - **CRT** → Android  

2. Import the certs into your device’s trusted store.  
3. Configure LiveSync plugin → Server address, port, and credentials.  
4. Test the connection (should work with TLS).

## 🪟 Running & Building on Windows (Line Endings Fix)

If you build this image on Windows (Docker Desktop), ensure that **all shell scripts (`.sh`) and OpenSSL config files (`.cnf`) in the `scripts` directory use Unix (LF) line endings**.  
By default, Git on Windows may convert them to Windows (CRLF), which breaks execution inside the container.

You can fix line endings in two ways:

1. **Using `dos2unix` (recommended):**  

   Install `dos2unix` via Chocolatey if you don't have it:
   ```powershell
   choco install dos2unix
   ```

   Then convert all scripts and config files:
   ```powershell
   dos2unix .\scripts\*.sh
   dos2unix .\scripts\*.cnf
   ```

2. **Using PowerShell:**  

   If you don't want to install extra tools, run this PowerShell snippet in your project root:
   ```powershell
   Get-ChildItem -Path .\scripts\*.sh,.\scripts\*.cnf | ForEach-Object {
       (Get-Content $_.FullName) -replace "`r", "" | Set-Content -NoNewline $_.FullName
   }
   ```

Then build the image as usual:
```powershell
docker build -t livesync-couchdb-tls .
```

And run the container (example):
```powershell
docker run -d --name livesync-couchdb-tls `
  -p 5984:5984 -p 6984:6984 `
  -e COUCHDB_USER=admin `
  -e COUCHDB_PASSWORD=password123 `
  -e COUCHDB_CN=domain.example `
  livesync-couchdb-tls:latest
```

Docker Compose:
```yaml
version: '3'
services:
  livesync-couchdb-tls:
    image: livesync-couchdb-tls:latest
    container_name: livesync-couchdb-tls
    ports:
      - "5984:5984"
      - "6984:6984"
    environment:
      COUCHDB_USER: admin
      COUCHDB_PASSWORD: password123
      COUCHDB_CN: domain.example
```

This will ensure your container builds and runs correctly on Windows.

## ⚙️ Internal Logic

- Built on **Debian 12 + CouchDB**  
- SSL Root CA created at build, runtime certs generated on start  
- Smart CN detection (IP vs DNS)  
- Entrypoint handles CouchDB init + SSL config  
- Root CA certs available via import script

## 📜 License

MIT — use freely for personal or commercial projects.
