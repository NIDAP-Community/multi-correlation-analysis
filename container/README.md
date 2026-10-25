# Container validation

Build a local AMD64 image from the repository root:

```bash
container/build_docker.sh multi-correlation-analysis:local
```

Then run the public-interface smoke test:

```bash
container/smoke_test.sh multi-correlation-analysis:local
```

The scripts use BuildKit and accept `DOCKER_CA_CERT=/path/to/trusted-root.pem` on HTTPS-inspecting networks. The PEM is mounted only as a build secret and is never retained in the image.

The image is deliberately not published to GHCR until this smoke test passes and a GitHub repository has been reviewed.
