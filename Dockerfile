FROM php:5.4.45-apache

EXPOSE 80

# Install dependencies
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libbz2-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev; \
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr; \
	docker-php-ext-install bz2 gd mysqli zip; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

ENV VERSION 4.0.10.20

ENV SHA256 4341a44a2fd40b3620492f5d12df9f24318e323bb3c35d0e64adc811af31fb02

ENV URL https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.gz

RUN curl -fsSL -o phpMyAdmin.tar.xz $URL; \
    echo "$SHA256 *phpMyAdmin.tar.xz" | sha256sum -c -; \
    tar -xf phpMyAdmin.tar.xz -C /var/www/html --strip-components=1; \
    mkdir -p /var/www/html/tmp; \
    chown www-data:www-data /var/www/html/tmp; \
    rm -rf /var/www/html/setup/ /var/www/html/examples/ /var/www/html/RELEASE-DATE-${VERSION}; \
    sed -i "s@define('CONFIG_DIR'.*@define('CONFIG_DIR', '/etc/phpmyadmin/');@" /var/www/html/libraries/vendor_config.php; \
    # Add directory for sessions to allow session persistence
    mkdir /sessions;

# Copy configuration
COPY config.inc.php /etc/phpmyadmin/config.inc.php
COPY php.ini /usr/local/etc/php/conf.d/php-phpmyadmin.ini

# Copy main script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["apache2-foreground"]
