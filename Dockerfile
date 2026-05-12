# Thunder Choreo Deployment Dockerfile
# Uses the latest pre-built Thunder image with Choreo security requirements

FROM ghcr.io/asgardeo/thunderid:latest

USER root

RUN apk add --no-cache jq sqlite

# Create a symlink: /opt/thunderid/tmp -> /tmp
# This allows deployment.yaml to use relative path "tmp/..." which resolves
# through the symlink to /tmp/... (the only writable directory in Choreo)
RUN ln -s /tmp /opt/thunderid/tmp

# Copy Choreo-optimized configs
COPY deployment.yaml /opt/thunderid/repository/conf/deployment.yaml
COPY entrypoint.sh /opt/thunderid/entrypoint.sh
COPY 99-cfp-tracker-app.sh /opt/thunderid/bootstrap/99-cfp-tracker-app.sh

RUN chmod +x /opt/thunderid/entrypoint.sh /opt/thunderid/bootstrap/99-cfp-tracker-app.sh

# Disable consent server
ENV WITH_CONSENT=false

# Fix permissions (Choreo requires numeric UID 10000-20000)
RUN chown -R 10001:10001 /opt/thunderid && \
    chmod -R u+rwX,g+rX,o+rX /opt/thunderid

USER 10001

EXPOSE 8090

CMD ["/opt/thunderid/entrypoint.sh"]
