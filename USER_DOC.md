# User Documentation

This document explains how to use the Inception infrastructure as a website user or system administrator.

> **Before you begin:** Replace `eabushak` with your 42 login and check that the commands, service names, Makefile targets, and secret-file locations match your repository. This guide follows the requirements of the Inception subject; exact implementation details may differ.

## 1. Services provided

The stack consists of three separate Docker services:

- **NGINX** — the public HTTPS entry point. It accepts connections on port 443 and must allow only TLSv1.2 and/or TLSv1.3.
- **WordPress + PHP-FPM** — serves the WordPress application and processes PHP requests. It does not contain NGINX.
- **MariaDB** — stores WordPress database information. It runs separately and does not contain NGINX.

The containers communicate through a dedicated Docker network. Two Docker named volumes preserve the database and WordPress website files. Their data must be stored under `/home/eabushak/data` on the host machine.

Only NGINX should be reachable from outside the Docker network, through port 443.

## 2. Start the website

### Before starting

1. Make sure the virtual machine is running and Docker is available.
2. Confirm that your login-specific domain, `eabushak.42.fr`, resolves to the virtual machine's local IP address.
3. Confirm that the required environment configuration and local secret files are present.
4. Ensure the persistent-data location `/home/eabushak/data` is configured correctly.

From the repository root, inspect the available Makefile targets:

```bash
cat Makefile
```

Use the project's documented startup target. Depending on the Makefile, it may be:

```bash
make
```

or:

```bash
make up
```

Do not assume both targets exist; use the target actually defined in your repository. The Makefile should build and launch the application using Docker Compose.

If you need to start the stack directly for troubleshooting, and your Compose file is located at `srcs/docker-compose.yml`, use the command supported by your Docker installation:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

Some installations use `docker-compose` instead of `docker compose`.

## 3. Access the website

Once the services are running and the domain points to the VM, open:

```text
https://eabushak.42.fr
```

The site must be accessed through HTTPS on port 443. If the project uses a self-signed or locally generated certificate, the browser may show a certificate warning. Verify that the certificate belongs to your local project before proceeding.

### WordPress administration panel

Open:

```text
https://eabushak.42.fr/wp-admin
```

Sign in with the WordPress administrator account configured during installation. The administrator username must follow the subject's restriction: it must not contain `admin` or `administrator` in the prohibited forms.

## 4. Locate and manage credentials

Credentials are sensitive. Never publish passwords, private keys, or tokens in the Git repository, README, screenshots, or logs.

Depending on your implementation, local secret files may be stored in a root-level `secrets/` directory, for example:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

These are example filenames drawn from the subject's sample structure. Use the filenames configured in your actual project. Environment variables and non-sensitive configuration are typically defined in `srcs/.env`; confidential values should be handled with the configured secret mechanism where supported.

Recommended practices:

- Keep secret files local and ignored by Git.
- Restrict permissions so only authorized users can read them.
- Do not place passwords in Dockerfiles.
- Do not commit actual credentials or private keys.
- If a credential is exposed, rotate it and remove it from tracked files and history as appropriate.
- Store and share credentials only through an approved secure method.

The exact credentials and file locations depend on your implementation. This document intentionally does not include actual usernames or passwords.

## 5. Check that services are running correctly

From the repository root, run:

```bash
docker ps
docker compose -f srcs/docker-compose.yml ps
```

Check that the NGINX, WordPress/PHP-FPM, and MariaDB containers are running. Use the actual service names if they differ.

View the logs when a service does not work:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

You can also view all service logs:

```bash
docker compose -f srcs/docker-compose.yml logs
```

The commands above assume Compose service names `nginx`, `wordpress`, and `mariadb`; substitute your actual names if needed.

Additional checks:

```bash
docker network ls
docker volume ls
```

Confirm that the three services share the intended dedicated network and that the two named volumes exist. Confirm that only NGINX is published to the host on port 443 and that the application is reachable through the configured domain.

## 6. Stop the website

Check the Makefile for the supported stop target:

```bash
cat Makefile
```

If your project defines `down`, use:

```bash
make down
```

Otherwise, from the repository root, you can stop and remove the Compose containers with:

```bash
docker compose -f srcs/docker-compose.yml down
```

Stopping the stack does not normally delete named-volume data. The database and website files should remain available when the stack is started again.

> **Warning:** Do not use `docker compose down -v` unless you intentionally want to remove Compose-managed volumes and their data. Removing persistent volumes can delete the WordPress database and website files.

## 7. Common problems

### The domain does not resolve

- Check that `eabushak.42.fr` is mapped to the VM's local IP address.
- Check the hosts/DNS configuration on the machine running the browser.
- Confirm that the VM IP has not changed.

### The website cannot be reached over HTTPS

- Confirm that the NGINX container is running.
- Check that port 443 is published and not blocked.
- Review the NGINX logs and TLS certificate configuration.
- Confirm that the enabled TLS versions are TLSv1.2 and/or TLSv1.3.

### WordPress reports a database connection error

- Check the MariaDB container logs.
- Confirm that WordPress and MariaDB are attached to the same Docker network.
- Verify the database name, username, and secret configuration without publishing passwords.
- Allow for database initialization to complete, then recheck the logs.

### A container keeps restarting or exits

- Inspect the service logs.
- Check configuration files, permissions, and startup scripts.
- Do not use infinite-loop workarounds such as `tail -f`, `sleep infinity`, or `while true` to keep a container alive.

### Website or database data appears to be missing

- Check the named volumes and their configured host storage location.
- Verify the configuration points to `/home/eabushak/data` and uses Docker named volumes rather than bind mounts for the two persistent stores.
- Avoid deleting volumes when stopping or rebuilding containers.

## 8. Data persistence

The stack must use two Docker named volumes:

1. One for MariaDB database data.
2. One for WordPress website files.

The volume configuration must place the data under:

```text
/home/eabushak/data
```

Replace `eabushak` with your actual login. The precise subdirectory names depend on your Compose configuration. These must remain named volumes, not bind mounts. Containers can be recreated while persistent data remains in the volumes, provided the volumes are not deleted.

## 9. Safety reminders

- Keep credentials out of Git and public documentation.
- Do not expose MariaDB or PHP-FPM directly to the host.
- Use HTTPS through NGINX on port 443.
- Protect local secret files with suitable permissions.
- Do not delete persistent volumes unless data deletion is intended.
