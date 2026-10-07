FROM nginx:1.31.6

# Non-root Nginx runtime configuration
RUN sed -i 's|^pid .*|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf

# Apply available security updates
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get remove -y curl libxml2 libexpat1 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/run

COPY --chown=nginx:nginx index.html /usr/share/nginx/html/index.html

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

USER 101:101

EXPOSE 8080
