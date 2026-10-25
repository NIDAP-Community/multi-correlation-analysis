# syntax=docker/dockerfile:1
# Build locally with: container/build_docker.sh multi-correlation-analysis:local
FROM rocker/r-ver:4.5.2

ARG VCS_REF=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="Multi-Correlation Analysis" \
      org.opencontainers.image.description="Portable gene-gene correlation analysis with category-specific heatmaps and significance tables." \
      org.opencontainers.image.source="https://github.com/NIDAP-Community/multi-correlation-analysis" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

# Use a build secret only while retrieving packages on institutional networks
# that inspect HTTPS; the certificate is not copied into the finished image.
RUN --mount=type=secret,id=build_ca,required=false \
    if [ -s /run/secrets/build_ca ]; then export CURL_CA_BUNDLE=/run/secrets/build_ca; fi; \
    apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates libcurl4-openssl-dev libssl-dev libxml2-dev \
      libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev && \
    rm -rf /var/lib/apt/lists/*

RUN --mount=type=secret,id=build_ca,required=false \
    if [ -s /run/secrets/build_ca ]; then export CURL_CA_BUNDLE=/run/secrets/build_ca; fi; \
    R --vanilla -s -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); install.packages("corrplot")' && \
    R --vanilla -s -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); install.packages("https://github.com/CCBR/l2p/raw/master/l2p_0.0-14.tar.gz", repos = NULL)'

WORKDIR /app
COPY R /app/R
COPY entrypoint.R /app/entrypoint.R
COPY test_data /app/test_data
COPY scripts/smoke_test.R /app/scripts/smoke_test.R
RUN Rscript --vanilla /app/scripts/smoke_test.R

ENTRYPOINT ["Rscript", "/app/entrypoint.R"]
CMD ["--help"]
