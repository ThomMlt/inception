# Inception

*This project has been created as part of the 42 curriculum by tmillot.*

## Description

**Inception** is a system administration and DevOps project that focuses on containerization using Docker. The goal is to set up a small infrastructure composed of multiple services, each running in its own isolated container, following specific security and architectural requirements.

This project implements a complete web infrastructure with:
- **NGINX** web server with TLSv1.2/1.3 encryption
- **WordPress** content management system with PHP-FPM
- **MariaDB** database server

All services communicate through a dedicated Docker network, with persistent data storage using Docker volumes, demonstrating modern containerization best practices and microservices architecture.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         Host Machine                              │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              Docker Network (inception)                    │  │
│  │                                                            │  │
│  │  ┌─────────────┐        ┌─────────────┐                  │  │
│  │  │   NGINX     │───────▶│  WordPress  │                  │  │
│  │  │  (Port 443) │ 9000   │  + PHP-FPM  │                  │  │
│  │  │   TLS 1.3   │FastCGI │  (Port 9000)│                  │  │
│  │  └──────┬──────┘        └──────┬──────┘                  │  │
│  │         │                      │                          │  │
│  │         │    ┌────────────┐    │                          │  │
│  │         └───▶│ WordPress  │◀───┘                          │  │
│  │              │   Volume   │     │                          │  │
│  │              │  (Shared)  │     │                          │  │
│  │              └─────┬──────┘     │                          │  │
│  │                    │            │                          │  │
│  │                    │            ▼                          │  │
│  │                    │    ┌─────────────┐                   │  │
│  │                    │    │   MariaDB   │                   │  │
│  │                    │    │ (Port 3306) │                   │  │
│  │                    │    └──────┬──────┘                   │  │
│  │                    │           │                          │  │
│  └────────────────────┼───────────┼──────────────────────────┘  │
│                       │           │                              │
│              /var/www/wordpress   │                              │
│              (Bind Mount)         │                              │
│                       │           │                              │
│                       ▼           ▼                              │
│            ┌─────────────┐  ┌──────────────┐                    │
│            │  WordPress  │  │   MariaDB    │                    │
│            │    Files    │  │   Database   │                    │
│            └─────────────┘  └──────────────┘                    │
│                   │                 │                            │
│     /Users/tmillot/data/wordpress   │                            │
│                         /Users/tmillot/data/mariadb             │
│                                                                  │
│  External Access: https://tmillot.42.fr:443                     │
└──────────────────────────────────────────────────────────────────┘

Legend:
  ──────▶  Network communication
  │        Volume mount
  3306     Port number
```

## Instructions

### Prerequisites

- Docker Engine (version 20.10+)
- Docker Compose (version 2.0+)
- Make utility
- At least 2GB of free disk space

### Configuration

1. **Clone the repository:**
   ```bash
   git clone <repository-url> inception
   cd inception
   ```

2. **Configure domain name:**
   
   Add the following line to your `/etc/hosts` file:
   ```bash
   sudo sh -c 'echo "127.0.0.1  tmillot.42.fr" >> /etc/hosts'
   ```

3. **Environment variables:**
   
   The project uses a `.env` file located in `srcs/.env` with the following variables:
   ```env
   DOMAIN_NAME=
   MYSQL_DATABASE=
   MYSQL_USER=
   MYSQL_PASSWORD=
   MYSQL_ROOT_PASSWORD=
   WP_TITLE=
   WP_ADMIN_USER=
   WP_ADMIN_PASSWORD=
   WP_ADMIN_EMAIL=
   WP_USER=
   WP_USER_PASSWORD=
   WP_USER_EMAIL=
   ```

4. **Create data directories:**
   ```bash
   mkdir -p /Users/tmillot/data/mariadb
   mkdir -p /Users/tmillot/data/wordpress
   ```

### Building and Running

The project includes a Makefile with the following targets:

- **Build and start all services:**
  ```bash
  make
  # or
  make up
  ```

- **Stop services:**
  ```bash
  make stop
  ```

- **Stop and remove containers:**
  ```bash
  make down
  ```

- **Clean volumes and containers:**
  ```bash
  make clean
  ```

- **Full clean (including Docker cache):**
  ```bash
  make fclean
  ```

- **Rebuild everything:**
  ```bash
  make re
  ```

### Accessing the Services

Once the containers are running:

- **WordPress website:** https://tmillot.42.fr
- **WordPress admin panel:** https://tmillot.42.fr/wp-admin
  - Admin credentials: `wp_admin` / `admin_password`
  - User credentials: `wp_user` / `user_password`

- **Database access:**
  ```bash
  docker exec -it mariadb mysql -u wp_user -pwp_password wordpress
  ```

### Verifying the Installation

Check that all containers are running:
```bash
docker ps
```

You should see three containers:
- `nginx` (listening on port 443)
- `wordpress` (running PHP-FPM on port 9000)
- `mariadb` (running on port 3306)

Check container logs:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Verify data persistence:
```bash
ls -la /Users/tmillot/data/mariadb
ls -la /Users/tmillot/data/wordpress
```

## Project Description

### Docker Implementation

This project implements a multi-container Docker application using **Docker Compose** to orchestrate three interconnected services. Each service runs in its own isolated container, built from custom Dockerfiles based on **Debian Bullseye**.

#### Container Architecture

1. **NGINX Container**
   - Acts as the single entry point to the infrastructure
   - Handles HTTPS encryption (TLSv1.2/1.3 only)
   - Generates self-signed SSL certificates on first run
   - Proxies PHP requests to WordPress container via FastCGI
   - **Shares WordPress volume** to serve static files (CSS, JS, images) directly

2. **WordPress Container**
   - Runs PHP 7.4-FPM (no web server included)
   - Automatically downloads and configures WordPress using WP-CLI
   - Waits for MariaDB availability before initialization
   - Creates two users (admin and regular user)
   - Processes PHP files received from NGINX via FastCGI
   - **Shares WordPress volume** with NGINX for file access

3. **MariaDB Container**
   - Runs MariaDB 10.5 database server
   - Automatically initializes database on first run
   - Creates WordPress database and users
   - Uses marker file (`.initialized`) to prevent re-initialization
   - Stores data persistently in dedicated Docker volume

### Design Choices

#### Process Management
All containers use the **`exec` command** in their entrypoints to ensure the main process runs as **PID 1**. This is crucial for:
- Proper signal handling (SIGTERM, SIGKILL)
- Clean container shutdown
- Avoiding zombie processes
- Proper resource cleanup

#### Service Dependencies
The `depends_on` directive ensures:
- MariaDB starts before WordPress
- WordPress starts before NGINX
- Proper initialization order

However, `depends_on` only waits for container start, not service readiness. Therefore:
- WordPress actively waits for MariaDB to accept connections using `mysqladmin ping`
- This prevents race conditions during initialization

#### Data Persistence Strategy
- WordPress files and database data persist across container restarts
- Volumes are mapped to host directories for easy backup
- **NGINX and WordPress share the same WordPress volume** (`wordpress_data`) mounted at `/var/www/wordpress`
  - WordPress writes PHP files, uploads, themes, and plugins
  - NGINX reads these files to serve static content and proxy PHP requests
- MariaDB has its own dedicated volume (`mariadb_data`) at `/var/lib/mysql`
- This shared volume architecture allows NGINX to efficiently serve static assets without proxying through PHP-FPM

#### Security Considerations
- No passwords stored in Dockerfiles (all in `.env`)
- TLS 1.2/1.3 encryption enforced
- Self-signed certificates (production should use Let's Encrypt)
- Database accessible only within Docker network
- Root password different from application database password

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Full OS-level isolation with hypervisor | Process-level isolation using kernel features |
| **Resource Usage** | Heavy: includes full OS, kernel, drivers | Lightweight: shares host kernel |
| **Boot Time** | Minutes (full OS boot) | Seconds (process startup) |
| **Disk Space** | GBs per VM (entire OS image) | MBs per container (application layers) |
| **Performance** | Overhead from hypervisor | Near-native performance |
| **Portability** | Limited (hypervisor-specific) | Highly portable (runs anywhere with Docker) |
| **Use Case** | Strong isolation, different OS requirements | Microservices, rapid deployment, scaling |

**Why Docker for Inception:**
- Lightweight infrastructure suitable for microservices
- Fast deployment and testing iterations
- Easy service orchestration with Docker Compose
- Efficient resource utilization on single host
- Perfect for development and small-scale production

#### Secrets vs Environment Variables

| Feature | Secrets | Environment Variables |
|---------|---------|----------------------|
| **Security** | Encrypted at rest and in transit | Stored in plain text |
| **Visibility** | Not visible in `docker inspect` | Visible in `docker inspect`, logs, and process list |
| **Management** | Managed by orchestration platform | Stored in `.env` files or shell |
| **Access Control** | Fine-grained permissions | File system permissions only |
| **Updates** | Can be rotated without rebuilding | Requires container restart |
| **Best For** | Production credentials, API keys | Non-sensitive configuration |

**Implementation in Inception:**
- Uses **environment variables** via `.env` file
- Acceptable for educational/development purposes
- **Production recommendation:** Use Docker secrets or external secret management (HashiCorp Vault, AWS Secrets Manager)

**Example migration to secrets:**
```yaml
secrets:
  mysql_password:
    file: ./secrets/mysql_password.txt

services:
  mariadb:
    secrets:
      - mysql_password
```

#### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Network-isolated containers | Shares host network stack |
| **Port Mapping** | Explicit port mapping required | Direct access to host ports |
| **Security** | Container-to-container communication isolated | All ports exposed on host |
| **DNS** | Built-in service discovery (container names) | Must use localhost/IP |
| **Performance** | Slight overhead from NAT | Native performance |
| **Use Case** | Multi-container applications | High-performance networking |

**Inception uses Bridge Network:**
- **Service Discovery:** Containers communicate using names (`mariadb`, `wordpress`)
- **Security:** Database not exposed to host, only accessible via network
- **Port Control:** Only NGINX exposes port 443 externally
- **Flexibility:** Easy to add services without port conflicts

**Configuration:**
```yaml
networks:
  inception:
    driver: bridge
```

#### Docker Volumes vs Bind Mounts

| Feature | Docker Volumes | Bind Mounts |
|---------|---------------|-------------|
| **Management** | Managed by Docker CLI | Direct filesystem paths |
| **Location** | Docker storage directory | Any host path |
| **Portability** | Platform-independent | Platform-specific paths |
| **Performance** | Optimized by Docker | Direct I/O (faster on Linux) |
| **Backup** | `docker volume` commands | Standard filesystem tools |
| **Permissions** | Managed by Docker | Host filesystem permissions |
| **Sharing** | Easy container-to-container sharing | Manual path coordination |

**Inception Implementation:**
Uses **Docker volumes with bind mount driver options** (hybrid approach):

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /Users/tmillot/data/mariadb
```

**Benefits of this approach:**
- ✅ **Named volumes** for Docker Compose management
- ✅ **Explicit host paths** for easy backup and inspection
- ✅ **Data visibility** in `/Users/tmillot/data/`
- ✅ **Persistence** across container recreation
- ✅ **Sharing** between NGINX and WordPress containers

**Why not pure bind mounts:**
- Bind mounts bypass Docker's volume management
- Harder to track with `docker volume ls`
- No integration with Docker backup/restore tools

## Resources

### Documentation and Tutorials

#### Docker
- [Docker Official Documentation](https://docs.docker.com/) - Comprehensive Docker reference
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Multi-container Docker applications
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) - Official guidelines
- [Docker Security](https://docs.docker.com/engine/security/) - Security best practices

#### NGINX
- [NGINX Official Documentation](https://nginx.org/en/docs/) - Complete NGINX reference
- [NGINX SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html) - HTTPS setup guide
- [NGINX FastCGI Configuration](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/) - PHP-FPM integration

#### WordPress
- [WordPress.org](https://wordpress.org/) - Official WordPress site
- [WP-CLI Documentation](https://wp-cli.org/) - WordPress command-line interface
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/) - Best practices

#### MariaDB
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) - Official MariaDB documentation
- [MariaDB Security](https://mariadb.com/kb/en/securing-mariadb/) - Security hardening guide

#### System Administration
- [The Twelve-Factor App](https://12factor.net/) - Methodology for building SaaS apps
- [Linux Containers](https://linuxcontainers.org/) - Understanding containerization
- [Awesome Docker](https://awesome-docker.netlify.app/) - Curated list of Docker resources

### AI Usage in This Project

This project was developed with assistance from AI (GitHub Copilot / Claude) for the following tasks:

#### 1. **Configuration and Setup**
- Generated Dockerfile templates based on project requirements
- Created Docker Compose configuration with proper service dependencies
- Configured NGINX for HTTPS with FastCGI proxy to WordPress

#### 2. **Shell Script Development**
- Entrypoint scripts for proper service initialization
- Database initialization logic with idempotency checks
- WordPress automated installation using WP-CLI
- MariaDB bootstrap configuration

#### 3. **Troubleshooting and Debugging**
- Diagnosed container restart loops and connection issues
- Fixed MariaDB user permission problems
- Resolved volume persistence and initialization race conditions
- Network connectivity debugging between containers

#### 4. **Documentation**
- Generated comprehensive README structure
- Created architecture diagrams using ASCII art
- Explained technical comparisons (VM vs Docker, etc.)
- Documented best practices and design decisions

#### 5. **Code Review and Optimization**
- Reviewed Dockerfiles for best practices (proper PID 1 handling)
- Suggested security improvements (environment variables, secrets)
- Optimized service startup sequences and health checks

**Parts Written Without AI:**
- Original project requirements and constraints
- Final design decisions and architectural choices
- Custom configuration values (domain names, passwords)
- Manual testing and validation procedures

**AI Contribution Level:** ~75% code generation and troubleshooting, ~25% human decision-making and testing

## Troubleshooting

### Common Issues

**Issue:** "Connection refused" when accessing WordPress
- **Solution:** Check all containers are running: `docker ps`
- Verify NGINX logs: `docker logs nginx`

**Issue:** "502 Bad Gateway"
- **Cause:** WordPress container not responding
- **Solution:** Check WordPress logs: `docker logs wordpress`
- Ensure MariaDB is accessible from WordPress

**Issue:** Data not persisting
- **Solution:** Verify volume directories exist and have proper permissions
- Check: `ls -la /Users/tmillot/data/`

**Issue:** SSL certificate errors
- **Cause:** Self-signed certificate not trusted
- **Solution:** Accept the security warning in browser (development only)

### Useful Commands

```bash
# View all container logs
docker compose -f srcs/docker-compose.yml logs -f

# Restart a specific service
docker restart <container_name>

# Access container shell
docker exec -it <container_name> /bin/sh

# Check volume usage
docker volume ls
docker volume inspect mariadb_data

# Network inspection
docker network inspect srcs_inception

# Remove everything and start fresh
make fclean && make
```

## License

This project is part of the 42 School curriculum and is intended for educational purposes.

## Author

**tmillot** - 42 School Student

---

*Last updated: January 2026*
