# OpenLiteSpeed Docker Container

This repository hosts a user-maintained Docker image for [OpenLiteSpeed](https://openlitespeed.org/), the Open Source version of the highly optimized [LiteSpeed Web Server](https://www.litespeedtech.com/products/litespeed-web-server/overview). 

## Scope:
This container is intended to maintain compatibility and the internal container directory structure of the official OpenLiteSpeed docker container. Ideal for both development and production environments, it is designed to be as lightweight as possible while still providing a rich feature set for modern applications. Additional features allow for easy install and maintenance of multiple websites.

## Achievements:

- Adopted Debian Slim as base image, replacing Ubuntu :white_check_mark:
- Container supports native execution on x86_64 and aarch64 (Apple Silicon, Raspberry Pi) :white_check_mark:
- Enhanced readability of the `PHP_VERSION` argument :white_check_mark:

## Upcoming Improvements:

- Simplify integration with load-balancers and reverse proxies like Traefik
- Allow easy setup for multi-tenant web hosting
- Provide comprehensive instructions for building and running the container

## Future Roadmap:

- Detect .htaccess changes and apply automatically
- Improve control over default website and error pages at webserver and vhost level
- Implement SSL pass-through
- Implement QUIC/HTTP3 pass-through
- Automate deployment to Docker Hub upon release of updated PHP modules
- Compatibility with CloudFlare tunnel (True Client IP)
- Forward localhost ports to reverse proxied remote services, e.g. MySQL
- Implement Bubblewrap for enhanced security
- Per-tenant cgroup-style limits for CPU, memory, and disk I/O
- Environment variable to disable the WebAdmin interface
- Offer images that use Alpine Linux base

Please feel free to contribute or raise any issues you encounter during the usage of this Docker container.
