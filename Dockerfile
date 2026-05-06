# Thunder Choreo Deployment Dockerfile
# Based on thunder-demo by rajithacharith
# Uses the latest pre-built Thunder image and applies Choreo security requirements

# Use the latest Thunder image as base
FROM ghcr.io/asgardeo/thunder:latest

# Switch to root for configuration changes
USER root

# Install utilities needed for config
RUN apk add --no-cache jq

# Copy the Choreo-optimized deployment configuration
COPY deployment.yaml /opt/thunder/repository/conf/deployment.yaml

# Set permissions (Choreo requires numeric UID in range 10000-20000)
RUN chown -R 10001:10001 /opt/thunder && \
    chmod -R u+rwX,g+rX,o+rX /opt/thunder

# Switch to numeric thunder user (required by Choreo's Dockerfile scan)
USER 10001

# Expose Thunder's port
EXPOSE 8090

# Start Thunder
CMD ["/opt/thunder/start.sh"]
