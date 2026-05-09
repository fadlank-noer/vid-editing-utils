FROM node:22-alpine AS css-builder
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci
COPY src/assets/css/input.css src/assets/css/input.css
COPY src/app/views/ src/app/views/
RUN npx @tailwindcss/cli -i src/assets/css/input.css -o src/assets/css/style.css

FROM php:8.5.6-zts-alpine3.22

WORKDIR /app

COPY composer.json composer.lock ./

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer \
    && composer install --no-dev --no-interaction --optimize-autoloader

COPY src/ src/
COPY --from=css-builder /build/src/assets/css/style.css src/assets/css/style.css

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "src", "src/index.php"]