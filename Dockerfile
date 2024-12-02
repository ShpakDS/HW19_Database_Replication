FROM php:8.1-cli

RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql

CMD ["tail", "-f", "/dev/null"]