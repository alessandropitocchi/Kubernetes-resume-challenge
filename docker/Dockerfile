FROM php:7.4-apache

RUN docker-php-ext-install mysqli pdo pdo_mysql

COPY ecommerce-website/learning-app-ecommerce/ /var/www/html

EXPOSE 80