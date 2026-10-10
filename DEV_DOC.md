# Developer Documentation

This document describes how to prepare, configure, build, run, inspect, and maintain the Inception project as a developer.

> **Important:** This guide is based on the Inception subject requirements and the example directory structure in the subject. Replace `eabushak` with your actual 42 login. Verify service names, Makefile targets, paths, variable names, and secret handling against the implementation in this repository.

## 1. Architecture and requirements

The project runs inside a virtual machine and uses Docker Compose to orchestrate three custom-built services:

- **NGINX** — public entry point, HTTPS only on host port 443, with TLSv1.2 and/or TLSv1.3.
- **WordPress + PHP-FPM** — WordPress application and PHP processing, without NGINX.
- **MariaDB** — database service, without NGINX.

Each service has its own container and custom Dockerfile. Each image must have the same name as its corresponding service. Use the penultimate stable version of Alpine or Debian as the base for each image, as required by the subject. Do not pull ready-made service images; Alpine/Debian base images are the stated exception. Do not use the `latest` tag.

The containers communicate through a dedicated Docker network. Two Docker named volumes persist the database and website files under `/home/eabushak/data` on the host. Containers must restart after a crash. Do not use host networking, `--link`, legacy `links:`, or infinite-loop container keepalive commands such as `tail -f`, `bash`, `sleep infinity`, or `while true`.

## 2. Repository layout

The subject expects a root-level Makefile and project configuration under `srcs/`. A representative layout is:

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            └── tools/
```

This is an illustrative layout; do not create empty directories solely to match it if your implementation does not need them. The root of the Git repository must contain `README.md`, `USER_DOC.md`, and `DEV_DOC.md`.

## 3. Prerequisites

On the virtual machine, install:

- Docker Engine.
- Docker Compose plugin (`docker compose`) or the compatible standalone `docker-compose` command.
- GNU Make.
- Git, if you need to clone the repository.

Verify the tools:

```bash
docker --version
docker compose version
make --version
git --version
```

If your system uses the standalone Compose command, check it with:

```bash
docker-compose --version
```

Make sure your user has permission to run Docker commands or use `sudo` as appropriate for your VM.

## 4. Set up the environment from scratch

### 4.1 Obtain the source

Clone your repository and enter the repository root. The root is the directory containing the Makefile.

### 4.2 Configure the domain

The required domain is:

```text
eabushak.42.fr
```

Configure it to resolve to the virtual machine's local IP address. For local testing, add an entry to the hosts file of the machine running the browser, if appropriate:

```text
<VM_LOCAL_IP> eabushak.42.fr
```

Replace both placeholders with the correct values. If the browser runs on another machine, configure name resolution on that machine too.

### 4.3 Configure environment variables

Review `srcs/.env`. It should define the environment variables expected by `docker-compose.yml` and the service configuration, such as the domain and non-sensitive database/application settings.

Check the variable names used by Compose, Dockerfiles, and initialization scripts; names must match exactly. Do not add real passwords to a tracked `.env` file.

### 4.4 Configure secrets

Inspect the Compose file and initialization scripts to determine the expected secret paths and names. The subject's example shows a root-level `secrets/` directory with files such as:

```text
secrets/credentials.txt
secrets/db_password.txt
secrets/db_root_password.txt
```

These are examples, not a guarantee that your implementation uses these exact names. Create the files your configuration actually references, with the expected contents and restrictive permissions. Use Docker secrets when supported and correctly configured. Do not commit secret files, credentials, API keys, passwords, or private keys.

Check `.gitignore` to ensure that actual secret files and other sensitive local configuration are excluded. A `.env` file is convenient for environment configuration but should not be treated as a secure secret store.

### 4.5 Prepare persistent data storage

The subject requires two Docker named volumes:

- Database storage.
- WordPress website-file storage.

Their data must be stored under:

```text
/home/eabushak/data
```

Replace `eabushak` with your actual login. Ensure the configured host storage directory exists and that the relevant services can write to the required directories. Configure these as Docker named volumes (for example, using an appropriate local volume-driver configuration), not as Compose bind mounts. Verify the effective mount configuration after startup.

## 5. Build and launch with the Makefile and Docker Compose

The Makefile at the repository root must set up the complete application and build the Docker images using `docker-compose.yml`.

First inspect the targets:

```bash
cat Makefile
```

If a help target exists, use it to list available commands:

```bash
make help
```

Use the targets actually defined in your Makefile. A typical project may support:

```bash
make
make up
make down
```

Do not assume all of these targets exist; the Makefile in your repository is authoritative.

For configuration validation and direct troubleshooting, if the Compose file is at `srcs/docker-compose.yml`:

```bash
docker compose -f srcs/docker-compose.yml config
```

Build the services:

```bash
docker compose -f srcs/docker-compose.yml build
```

Start the stack in the background:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

Use `docker-compose` instead if that is the installed command. Prefer the Makefile for the standard project workflow, and use direct Compose commands when useful for debugging.

## 6. Container lifecycle and diagnostic commands

### Inspect service status

```bash
docker ps
docker compose -f srcs/docker-compose.yml ps
```

### Read logs

```bash
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

The per-service examples assume service names `nginx`, `wordpress`, and `mariadb`. Replace them with the exact names in your Compose file.

### Follow logs while debugging

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Stop following logs with `Ctrl+C`; this detaches the log viewer and does not itself stop the services.

### Inspect a container

```bash
docker inspect <container_name_or_id>
docker exec -it <container_name_or_id> sh
```

Use a shell available in the image. Do not assume Bash is installed, and do not use an infinite loop or shell command as a container keepalive workaround.

### Inspect networks and volumes

```bash
docker network ls
docker volume ls
docker network inspect <network_name>
docker volume inspect <volume_name>
```

To inspect mount paths on a running container:

```bash
docker inspect <container_name_or_id>
```

Check the `Mounts` information in the output to verify volume destinations and storage configuration.

### Stop and remove containers

Use the Makefile's stop target if it exists:

```bash
make down
```

Or use Compose:

```bash
docker compose -f srcs/docker-compose.yml down
```

This normally removes the Compose containers and network but retains named volumes. Do not add `-v` unless you intentionally want to remove Compose-managed volumes and potentially delete persistent data.

### Rebuild after a change

After changing a Dockerfile or a file copied into an image, rebuild the affected service and recreate its container. For example:

```bash
docker compose -f srcs/docker-compose.yml build <service_name>
docker compose -f srcs/docker-compose.yml up -d <service_name>
```

Use the actual service name. If a configuration is mounted or read at runtime, follow the project's design to apply it; a full image rebuild may not always be necessary. Check the logs after applying changes.

## 7. Data persistence and volumes

The database and WordPress website files must be stored in separate Docker named volumes. Their host data must be located under `/home/eabushak/data`, with `eabushak` replaced by the actual login.

Verify:

1. The Compose file declares two named volumes.
2. The service mount entries reference those volume names.
3. The volumes are configured to store data at the required host location.
4. The effective mounts are not Compose bind mounts.
5. Recreating containers does not remove or overwrite persistent data.

Use:

```bash
docker volume ls
docker volume inspect <volume_name>
docker inspect <container_name_or_id>
```

Avoid `docker compose down -v`, `docker volume rm`, or other volume-removal commands unless a deliberate data reset is required. If you need to reset a development environment, confirm which data will be lost and back up anything important first.

## 8. Configuration, security, and networking checks

Before considering the stack ready, verify the following:

- NGINX is the only entry point from outside the Docker network.
- Only host port 443 is published for the web infrastructure.
- NGINX permits only TLSv1.2 and/or TLSv1.3.
- WordPress/PHP-FPM and MariaDB do not contain NGINX and are not publicly exposed.
- All services share the dedicated Docker network.
- No `network: host`, `--link`, or legacy `links:` is used.
- Each service has its own custom Dockerfile and dedicated container.
- Images use the permitted base-image versions and no `latest` tag.
- No passwords are written in Dockerfiles.
- Credentials are not committed to Git or exposed in logs.
- The required environment variables and `.env` file are present.
- Secret files are protected and ignored by Git where appropriate.
- Containers have a restart policy so they restart after a crash.
- No infinite-loop keepalive command is used; each container runs its intended service process correctly.
- The WordPress database contains two users, one of whom is an administrator. The administrator username must not contain the prohibited `admin`/`administrator` forms.
- The domain `eabushak.42.fr` resolves to the VM's local IP.
- The named volumes store data under `/home/eabushak/data`.
- `README.md`, `USER_DOC.md`, and `DEV_DOC.md` exist at the repository root.

## 9. Troubleshooting workflow

When a service fails, investigate in this order:

1. Check container state with `docker compose ... ps`.
2. Read the logs for the affected service.
3. Validate the rendered Compose configuration with `docker compose ... config`.
4. Check environment-variable names and secret-file paths without printing sensitive values.
5. Check service names and network membership.
6. Check volume mounts, ownership, and permissions.
7. Rebuild/recreate only the affected service when appropriate.
8. Retest HTTPS and verify that persistent data remains intact.

Common issues:

- **Build failure:** check Dockerfile syntax, base-image availability, package names for the selected Alpine/Debian release, and build context paths.
- **NGINX does not start:** inspect its configuration, certificate/key paths, permissions, and port mapping.
- **WordPress cannot connect to MariaDB:** confirm both services use the same network and agree on the database hostname, database name, user, and secret values.
- **Domain fails:** verify the hosts/DNS entry and VM address.
- **Permission denied:** inspect file ownership and the volume's host storage configuration.
- **Container exits:** inspect the service process and startup configuration; do not mask the failure with `tail -f`, `sleep infinity`, or an infinite loop.

## 10. References

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [PHP documentation](https://www.php.net/docs.php)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)

## 11. Developer handover checklist

- [ ] A new developer can identify prerequisites and configure the environment from scratch.
- [ ] Domain, `.env`, and secret-file configuration is documented and matches the implementation.
- [ ] Makefile and Compose build/start/stop commands have been tested.
- [ ] Container, network, and volume diagnostic commands work with the actual service names.
- [ ] Persistent storage location and named-volume configuration have been verified.
- [ ] The stack exposes only NGINX on port 443.
- [ ] No credentials are committed or embedded in Dockerfiles.
- [ ] Data-loss risks of volume-removal commands are understood.
- [ ] The developer can explain the service separation, network design, TLS configuration, and persistence choices.
