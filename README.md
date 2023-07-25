# OpenLiteSpeed Docker Container

This is a Docker image for [OpenLiteSpeed](https://openlitespeed.org/), the Open Source edition of [LiteSpeed Web Server](https://www.litespeedtech.com/products/litespeed-web-server/overview).

To Do:
- Use debian:bullseye-slim as base image instead of ubuntu:22.04 ✅
- Ensure container can run natively on Raspberry Pi and Apple Silicon (aaarch64) ✅
- Change PHP_VERSION argument to more human readable format ✅
- Easily route into proxy like Traefik
- Write instructions for building and running the container
- Customize the configuration to allow for hosting multple sites
- Easily modify default website and error pages
- SSL
- SSL Pass-through
- Automated deployment to Docker Hub when new PHP module versions are released
- Add ability to completely disable WebAdmin interface
- Provide iamges using Alpine Linux as a base