# Dockerfile
FROM nginx

COPY nginx.config /etc/nginx/nginx.config

RUN rm -rf /usr/share/nginx/html/*

COPY html /usr/share/nginx/html

EXPOSE 8080
 
CMD ["nginx", "-g", "daemon off;"]
