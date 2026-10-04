FROM tomcat:10.1.60-jdk17-temurin

# Apply available security updates to OpenSSL libraries
RUN apt-get update \
    && apt-get install -y --only-upgrade openssl libssl3t64 \
    && rm -rf /var/lib/apt/lists/*

# Remove Tomcat's default application
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Deploy the AcmeCloud application
COPY --chown=1000:1000 src/ /usr/local/tomcat/webapps/ROOT/

# Allow the non-root Tomcat runtime user to write only to runtime directories.
RUN mkdir -p /usr/local/tomcat/conf/Catalina/localhost \
    && chown -R 1000:1000 \
      /usr/local/tomcat/logs \
      /usr/local/tomcat/temp \
      /usr/local/tomcat/work \
      /usr/local/tomcat/webapps \
      /usr/local/tomcat/conf/Catalina

USER 1000:1000

EXPOSE 8080
