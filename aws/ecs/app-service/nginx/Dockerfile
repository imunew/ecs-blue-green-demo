FROM nginx:1.18

# Add sources, configs
ADD ./aws/ecs/app-service/nginx/etc/nginx.conf /etc/nginx/nginx.conf
ADD ./app/public /var/www/app/public

WORKDIR /var/www/app
