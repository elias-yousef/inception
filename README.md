*This activity has been created as part of the 42 curriculum by
eabushak.*

# Inception

## Description

Inception is a system-administration project from the 42 curriculum. Its
goal is to build and run a small, multi-service web infrastructure
inside a virtual machine using Docker and Docker Compose.

The infrastructure contains three dedicated services:

-   **NGINX** --- the only public entry point; serves HTTPS using
    TLSv1.2 and/or TLSv1.3.
-   **WordPress + PHP-FPM** --- runs the WordPress application and PHP
    processing, without NGINX.
-   **MariaDB** --- stores the WordPress database, without NGINX.

The services communicate over a dedicated Docker network. Two Docker
named volumes persist the database and website files. Containers must
restart after a crash, and the website is reached through the
learner-specific domain `eabushak.42.fr`, mapped to the virtual
machine's local IP address.

This README describes the intended architecture and common setup
workflow. Replace placeholders with the values used in your repository,
and ensure commands match your actual Makefile and configuration files.

## Project description

### Goals

-   Practise system administration in a virtual machine.
-   Build custom Docker images using one Dockerfile per service.
-   Orchestrate services with Docker Compose and a root-level Makefile.
-   Configure secure HTTPS access through NGINX.
-   Separate the web server, WordPress/PHP-FPM, and database into
    dedicated containers.
-   Persist application files and database data with Docker named
    volumes.
-   Manage configuration through environment variables and a `.env`
    file, and keep confidential credentials out of Git.
-   Understand container networking, storage, service lifecycle, and
    basic operational troubleshooting.

### Architecture

``` text
Browser
   |
   | HTTPS :443 (TLSv1.2 / TLSv1.3 only)
   v
NGINX container
   |
   | Dedicated Docker network
   v
WordPress + PHP-FPM container
   |
   | Dedicated Docker network
   v
MariaDB container

Persistent named volumes:
- WordPress database data -> /home/eabushak/data/
- WordPress website files -> /home/eabushak/data/
```

Only NGINX is exposed to the host, on port **443**. WordPress/PHP-FPM
and MariaDB are internal services and must not expose their service
ports publicly. The exact internal ports and volume subdirectories
depend on the implementation.

### Docker and the included sources

Docker packages each service and its dependencies into an image, then
runs each image in an isolated container. Docker Compose defines the
services, their build contexts, network, persistent volumes, environment
configuration, restart policy, and dependencies. The Makefile at the
repository root provides convenient commands to build and start the
complete application using `docker-compose.yml`.

The project source/configuration files belong in `srcs/`. A typical
layout is:

``` text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/                         # local secret files; never commit credentials
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

This is an example structure based on the subject; retain only files and
directories that actually exist in your repository. The subject also
requires `USER_DOC.md` and `DEV_DOC.md` at the repository root.

### Main design choices and required comparisons

#### Virtual Machines vs Docker

  -----------------------------------------------------------------------
  Virtual machine                     Docker
  ----------------------------------- -----------------------------------
  Virtualizes hardware and runs a     Runs isolated containers that share
  guest operating system.             the host kernel.

  Usually consumes more resources     Usually lighter and quicker to
  because each VM includes an         start because containers share the
  operating system.                   host kernel.

  Provides a separate OS boundary.    Provides process and resource
                                      isolation, but is not a VM and
                                      shares the host kernel.

  Useful when a separate kernel/OS is Useful for packaging and running
  required.                           individual services consistently.
  -----------------------------------------------------------------------

**Choice in this project:** the whole activity runs inside a virtual
machine, as required, and Docker containers run the individual
infrastructure services inside that VM.

#### Secrets vs Environment Variables

  -----------------------------------------------------------------------
  Secrets                             Environment variables
  ----------------------------------- -----------------------------------
  Intended for confidential values    Convenient for non-sensitive
  such as passwords and keys, with    configuration and for passing
  access controlled by the            settings to services.
  platform/configuration.             

  Can be supplied as protected files  May be exposed through container
  or through a secrets mechanism      inspection, process environments,
  supported by the deployment.        logs, or accidental dumps.

  Prefer for sensitive credentials    Use for values such as the domain
  when supported and correctly        name, database name, and usernames;
  configured.                         avoid committing passwords.
  -----------------------------------------------------------------------

**Choice in this project:** use a `.env` file for required
environment-variable configuration, but do not commit credentials. Use
Docker secrets for confidential information where supported by the
chosen Compose setup. Local secret files must be ignored by Git and
protected with appropriate file permissions. A `.env` file is not itself
a secure secret store.

#### Docker Network vs Host Network

  -----------------------------------------------------------------------
  Docker bridge/custom network        Host network
  ----------------------------------- -----------------------------------
  Services communicate over a         A container shares the host's
  Docker-managed network and can use  network namespace.
  service/container DNS names.        

  Allows service communication        Reduces network isolation and can
  without making every service        create port conflicts with host
  publicly accessible.                services.

  Makes the intended service topology Bypasses the normal
  explicit in Compose.                isolated-network model.
  -----------------------------------------------------------------------

**Choice in this project:** define a dedicated network in
`docker-compose.yml` and connect all three services to it. Do not use
`network: host`, `--link`, or the legacy `links:` option.

#### Docker Volumes vs Bind Mounts

  -----------------------------------------------------------------------
  Docker named volume                 Bind mount
  ----------------------------------- -----------------------------------
  Managed by Docker and referenced by Maps a specific host path directly
  a volume name.                      into a container.

  Suitable for persistent application Useful when a container needs
  data managed as Docker storage.     direct access to a particular host
                                      file or directory.

  Can be configured with the local    The host path is an explicit part
  volume driver to store data at a    of the mount configuration.
  specified host location.            
  -----------------------------------------------------------------------

**Choice in this project:** use two **named volumes**, not Compose bind
mounts, for persistent data. Configure them so their data is stored
under `/home/eabushak/data` on the host, replacing the placeholder
with your 42 login. Commonly, separate subdirectories are used for the
database and WordPress files. Verify the effective volume configuration
and host paths in your Compose file.

### Mandatory constraints checklist

Use this checklist to verify the implementation against the subject:

-   [ ] The project runs inside a virtual machine.
-   [ ] All configuration/source files required by the project are in
    `srcs/`.
-   [ ] A Makefile is present at the repository root and builds the
    application using Docker Compose.
-   [ ] There is one custom Dockerfile for each service: NGINX,
    WordPress/PHP-FPM, and MariaDB.
-   [ ] Each image has the same name as its corresponding service.
-   [ ] Each service runs in its own dedicated container.
-   [ ] Base images use the penultimate stable version of Alpine or
    Debian.
-   [ ] Ready-made service images are not pulled; Alpine/Debian base
    images are the stated exception.
-   [ ] NGINX is configured for TLSv1.2 and/or TLSv1.3 only.
-   [ ] WordPress and PHP-FPM are installed/configured in their own
    container, without NGINX.
-   [ ] MariaDB runs in its own container, without NGINX.
-   [ ] Two Docker named volumes persist database data and website
    files.
-   [ ] The named volumes store their data under
    `/home/eabushak/data` on the host; they are not declared as
    Compose bind mounts.
-   [ ] A dedicated Docker network connects the containers.
-   [ ] Containers have a restart policy so they restart after a crash.
-   [ ] No host networking, `--link`, or `links:` is used.
-   [ ] No infinite-loop workaround is used to keep a container alive
    (including `tail -f`, `bash`, `sleep infinity`, or `while true`);
    services run correctly as container processes, with appropriate PID
    1 behaviour.
-   [ ] The WordPress database contains two users, including an
    administrator whose username does not contain `admin` or
    `administrator` in any capitalization/form covered by the subject
    examples.
-   [ ] The domain is `eabushak.42.fr` and resolves to the VM's
    local IP address.
-   [ ] The `latest` tag is not used.
-   [ ] No passwords are written in Dockerfiles.
-   [ ] Environment variables are used and a `.env` file is present.
-   [ ] Credentials, API keys, and passwords are not committed to Git;
    use properly configured secrets for confidential values.
-   [ ] NGINX is the only public entry point, exposed through port 443
    only.
-   [ ] `README.md`, `USER_DOC.md`, and `DEV_DOC.md` are present at the
    repository root and written in Markdown; this README is in English.

## Instructions

### Prerequisites

On the virtual machine, install and configure:

-   Docker Engine.
-   Docker Compose (the plugin command `docker compose` or the
    standalone `docker-compose`, according to the installed version and
    your Makefile).
-   `make`.
-   Git, if you are cloning the repository.
-   Permission to run Docker commands, either through the appropriate
    group configuration or with `sudo`.

The subject does not prescribe a specific VM distribution or resource
allocation. Choose a supported environment and ensure Docker is
available.

### 1. Configure your login, domain, and secrets

1.  Clone the repository and enter its root directory.

2.  Replace `eabushak` in the configuration and documentation with
    your actual 42 login.

3.  Configure the domain as `eabushak.42.fr`.

4.  Configure the VM's hosts file so the domain resolves to the VM's
    local IP address. For local-only testing, the relevant entry
    commonly takes the form:

    ``` text
    <VM_LOCAL_IP> eabushak.42.fr
    ```

    Add it to the appropriate hosts file for the machine/browser used to
    access the site. DNS/hosts configuration must point to the VM's
    local IP, as required by the subject.

5.  Review `srcs/.env` and set the non-secret values required by your
    Compose file and service configuration.

6.  Put passwords and other confidential values in the secret files or
    secret mechanism expected by your implementation. Do not place
    passwords in Dockerfiles or commit credentials to Git. If the
    Compose configuration uses Docker secrets, confirm that the secret
    files exist at the configured paths.

7.  Ensure the host data directories under `/home/eabushak/data`
    exist and have suitable ownership/permissions for the services. Keep
    the data directories separate from the Git repository.

**Important:** the exact environment-variable names and secret filenames
depend on the files in your repository. Use the names your Compose file
and initialization scripts actually read; do not copy placeholder values
into a live deployment.

### 2. Build and start the infrastructure

From the repository root, inspect the Makefile targets first:

``` bash
make help
```

If the Makefile does not define a `help` target, inspect it directly:

``` bash
cat Makefile
```

Then use the targets provided by your project. A common workflow is:

``` bash
make
# or, if defined by the Makefile:
make up
```

The Makefile must orchestrate the build and startup through the
project's Docker Compose configuration. If you need to run Compose
directly for diagnosis, from the location containing the Compose file
use the command supported by your installation, for example:

``` bash
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up -d
```

If your installation uses `docker-compose`, substitute that command. Use
the Makefile as the normal project entry point and adjust commands if
your repository uses a different Compose path or target naming.

### 3. Access the website

Open the following address in a browser after the containers are healthy
and the domain resolves correctly:

``` text
https://eabushak.42.fr
```

The site should be reached over HTTPS on port 443. A browser warning may
occur if the project uses a locally generated/self-signed TLS
certificate; verify that the certificate is the one configured for this
project. Do not expose WordPress/PHP-FPM or MariaDB directly to the
host.

The WordPress administration panel is normally available at:

``` text
https://eabushak.42.fr/wp-admin
```

Use the WordPress account configured during installation. The
administrator username must follow the subject's restriction and must
not contain `admin`/`administrator` in the prohibited forms.

### 4. Check service health

Useful diagnostic commands include:

``` bash
docker ps
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
docker network ls
docker volume ls
```

Use the actual Compose service names if they differ from `nginx`,
`wordpress`, and `mariadb`. Check that all three containers are running,
the services can communicate over the dedicated network, the database
initializes without errors, and NGINX serves HTTPS on port 443. Also
verify that data survives a container recreation.

### 5. Stop and clean up

Use the Makefile's documented stop target if available, for example:

``` bash
make down
```

Or use Compose directly:

``` bash
docker compose -f srcs/docker-compose.yml down
```

Stopping/removing containers this way normally leaves named volumes and
their data intact. **Do not remove persistent volumes unless you
intentionally want to delete the database and website data.** Commands
such as `docker compose down -v` can delete the Compose-managed volumes
and should be used only when data loss is intended. Follow the targets
defined by your Makefile.

### Common troubleshooting

-   **Domain does not open:** check the hosts/DNS mapping, VM IP,
    browser machine, and NGINX port 443 configuration.
-   **HTTPS/TLS error:** inspect the NGINX configuration,
    certificate/key paths, certificate permissions, and enabled TLS
    protocol versions.
-   **WordPress cannot connect to MariaDB:** check service names,
    network membership, database/user settings, secret paths, and
    MariaDB logs.
-   **Container exits or repeatedly restarts:** inspect that service's
    logs and entrypoint/startup configuration. Do not keep it alive with
    an infinite-loop command.
-   **Permission errors on persistent data:** verify the named-volume
    configuration, host data paths, ownership, and permissions.
-   **Configuration changes are not applied:** validate the Compose
    configuration and rebuild/recreate the affected service using the
    Makefile or Compose.
-   **Credentials appear in Git:** remove them from tracked files,
    rotate exposed credentials, and ensure secret/configuration files
    are appropriately ignored. Removing a secret from the latest commit
    alone may not remove it from Git history.

## Credentials and security

-   Keep actual passwords, tokens, private keys, and other credentials
    out of the repository.
-   Commit a safe example configuration only if it contains no real
    secrets; never commit real `.env` values or secret files.
-   Use `.gitignore` for local secret files and sensitive environment
    configuration, while retaining any non-sensitive example file needed
    to document configuration.
-   Protect secret files with restrictive permissions and use Docker
    secrets when supported and configured.
-   Never put passwords in Dockerfiles, image build arguments, public
    logs, or documentation.
-   Expose only NGINX on port 443; keep database and PHP-FPM access
    internal to the Docker network.
-   Use explicit supported base-image versions; do not use the
    prohibited `latest` tag.

## Resources

The following are useful reference sources for understanding and
implementing this activity:

-   [Docker documentation](https://docs.docker.com/) --- Docker
    concepts, images, containers, storage, networking, and security.
-   [Docker Compose documentation](https://docs.docker.com/compose/) ---
    defining and operating a multi-container application.
-   [Dockerfile
    reference](https://docs.docker.com/reference/dockerfile/) ---
    Dockerfile instructions and image-building practices.
-   [Docker volumes
    documentation](https://docs.docker.com/engine/storage/volumes/) ---
    persistent Docker-managed storage.
-   [Docker networking
    documentation](https://docs.docker.com/engine/network/) ---
    container networking and network drivers.
-   [Docker secrets in
    Compose](https://docs.docker.com/compose/how-tos/use-secrets/) ---
    handling sensitive configuration in Compose.
-   [NGINX documentation](https://nginx.org/en/docs/) --- web-server
    configuration.
-   [WordPress documentation](https://wordpress.org/documentation/) ---
    installation, configuration, and administration.
-   [PHP documentation](https://www.php.net/docs.php) --- PHP and
    PHP-FPM background.
-   [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
    --- database setup, users, and administration.
-   [OpenSSL documentation](https://docs.openssl.org/) --- TLS
    certificates and cryptographic tools.

### Use of AI

AI tools may be used to reduce repetitive work, explore Docker and
system-administration concepts, help organize documentation, suggest
troubleshooting steps, and identify commands or topics to investigate.
Any AI-generated suggestions must be checked against the subject,
official documentation, the actual project files, and test results. AI
output must not be copied blindly: the learner must understand and be
able to explain every implementation choice and command, and should
review the work with peers.

## Related documentation

-   **`USER_DOC.md`** --- must explain, in simple terms, the services
    provided, how to start and stop the stack, how to access the website
    and administration panel, where credentials are located and how they
    are managed, and how to check that services are running correctly.
-   **`DEV_DOC.md`** --- must explain prerequisites, setup from scratch,
    configuration and secrets, building/launching with the Makefile and
    Docker Compose, container/volume management commands, and where data
    is stored and how it persists.
