# Thunder Choreo Deployment Dockerfile
# Uses the latest pre-built Thunder image with Choreo security requirements

# Use the latest Thunder image as base
FROM ghcr.io/asgardeo/thunder:latest

# Switch to root for configuration changes
USER root

# Install utilities
RUN apk add --no-cache jq

# Copy Choreo-optimized configs
COPY deployment.yaml /opt/thunder/repository/conf/deployment.yaml
COPY entrypoint.sh /opt/thunder/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /opt/thunder/entrypoint.sh

# Disable consent server globally
ENV WITH_CONSENT=false

# Set permissions (Choreo requires numeric UID in range 10000-20000)
RUN chown -R 10001:10001 /opt/thunder && \
    chmod -R u+rwX,g+rX,o+rX /opt/thunder

# Switch to numeric thunder user (required by Choreo's Dockerfile scan)
USER 10001

# Expose Thunder's port
EXPOSE 8090

# Run setup on first boot, then start Thunder without consent server
CMD ["/opt/thunder/entrypoint.sh"]
