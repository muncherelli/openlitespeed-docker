# OpenLiteSpeed Docker Container

This is a Docker image for [OpenLiteSpeed](https://openlitespeed.org/), the Open Source edition of [LiteSpeed Web Server](https://www.litespeedtech.com/products/litespeed-web-server/overview).

To Do:
- Use debian:bullseye-slim as base image instead of ubuntu:22.04
- Provide Alpine Linux based image
- Allow images for both x86-64 and aarch64 to be built
- Write instructions for building and running the container
- Customize the configuration to allow for hosting multple sites
- Easily modify default website and error pages
- Automated deployment to Docker Hub when new PHP module versions are released
- Support for multiple PHP versions and multiple PHP modules
- Add ability to disable WebAdmin interface