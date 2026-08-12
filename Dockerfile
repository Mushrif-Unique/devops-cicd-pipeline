FROM nginx:alpine

COPY app/index.html /usr/share/nginx/html/index.html
COPY app/style.css /usr/share/nginx/html/style.css

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]