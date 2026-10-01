FROM nginx:1.31.6

# Apply available security updates
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get remove -y curl libxml2 libexpat1 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY index.html /usr/share/nginx/html/index.html

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
