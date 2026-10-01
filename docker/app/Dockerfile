FROM tomcat:10.1.60-jdk17-temurin

# Apply available security updates to OpenSSL libraries
RUN apt-get update \
    && apt-get install -y --only-upgrade openssl libssl3t64 \
    && rm -rf /var/lib/apt/lists/*

# Remove Tomcat's default application
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Deploy the AcmeCloud application
COPY src/ /usr/local/tomcat/webapps/ROOT/

EXPOSE 8080
