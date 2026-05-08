# Thunder Choreo Deployment Dockerfile
# Uses the latest pre-built Thunder image with Choreo security requirements

FROM ghcr.io/asgardeo/thunder:0.36.0

USER root

RUN apk add --no-cache jq sqlite

# Create a symlink: /opt/thunder/tmp -> /tmp
# This allows deployment.yaml to use relative path "tmp/..." which resolves
# through the symlink to /tmp/... (the only writable directory in Choreo)
RUN ln -s /tmp /opt/thunder/tmp

# Copy Choreo-optimized configs
COPY deployment.yaml /opt/thunder/repository/conf/deployment.yaml
COPY entrypoint.sh /opt/thunder/entrypoint.sh

RUN chmod +x /opt/thunder/entrypoint.sh

# Disable consent server
ENV WITH_CONSENT=false

# Fix permissions (Choreo requires numeric UID 10000-20000)
RUN chown -R 10001:10001 /opt/thunder && \
    chmod -R u+rwX,g+rX,o+rX /opt/thunder

USER 10001

EXPOSE 8090

CMD ["/opt/thunder/entrypoint.sh"]
