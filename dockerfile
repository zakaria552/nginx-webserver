FROM nginx:latest
COPY ./sites /usr/share/nginx/html
#COPY ./hosts /etc/hosts
COPY ./conf.d /etc/nginx/conf.d
RUN apt-get update && apt-get install --fix-missing -y 