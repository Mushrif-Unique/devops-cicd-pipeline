FROM nginx:latest

COPY app/index.html /usr/share/nginx/html/index.html

EXPOSE 80