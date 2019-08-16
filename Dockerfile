# -----------------------------------------------------------------------------------------------------------------------------------
# BUILDING CONTAINER
# -----------------------------------------------------------------------------------------------------------------------------------
FROM php:7.2-alpine as builder
LABEL maintainer="Lucas G. Diedrich <lucas.diedrich@gmail.com>"
WORKDIR /tmp/
ENV COMPOSER_ALLOW_SUPERUSER=1 \
        OMP_VERSION="3_1_2-1" \
        PACKAGES="curl nodejs npm git" \
        EXCLUDE="dbscripts/xml/data/locale/en_US/sample.xml					\
        dbscripts/xml/data/locale/te_ST								\
        dbscripts/xml/data/sample.xml								\
        docs/dev										\
        docs/doxygen										\
        lib/adodb/CHANGED_FILES									\
        lib/adodb/diff										\
        lib/smarty/CHANGED_FILES								\
        lib/smarty/diff										\
        locale/te_ST										\
        cache/*.php										\
        tools/buildpkg.sh									\
        tools/genLocaleReport.sh								\
        tools/genTestLocale.php									\
        tools/test										\
        lib/pkp/tools/travis									\
        lib/pkp/lib/vendor/smarty/smarty/demo							\
        plugins/generic/translator								\
        plugins/generic/customBlockManager/.git							\
        plugins/generic/emailLogger								\
        plugins/generic/staticPages/.git							\
        plugins/paymethod/paypal/vendor/omnipay/common/tests/					\
        plugins/paymethod/paypal/vendor/omnipay/paypal/tests/					\
        plugins/paymethod/paypal/vendor/guzzle/guzzle/docs/					\
        plugins/paymethod/paypal/vendor/guzzle/guzzle/tests/					\
        plugins/paymethod/paypal/vendor/symfony/http-foundation/Tests/				\
        lib/pkp/plugins/*/*/tests								\
        plugins/*/*/tests									\
        tests											\
        lib/pkp/tests										\
        .git											\
        .openshift										\
        .travis.yml										\
        lib/pkp/.git										\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/art						\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/benchmarks					\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/configdog					\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/docs						\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/extras						\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/maintenance					\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/smoketests					\
        lib/pkp/lib/vendor/ezyang/htmlpurifier/tests						\
        lib/pkp/lib/vendor/leafo/lessphp/tests							\
        lib/pkp/lib/vendor/leafo/lessphp/docs							\
        lib/pkp/lib/vendor/moxiecode/plupload/examples						\
        lib/pkp/lib/vendor/phpmailer/phpmailer/docs						\
        lib/pkp/lib/vendor/phpmailer/phpmailer/examples						\
        lib/pkp/lib/vendor/phpmailer/phpmailer/test						\
        lib/pkp/lib/vendor/robloach								\
        lib/pkp/lib/vendor/smarty/smarty/demo							\
        lib/pkp/lib/vendor/phpunit								\
        lib/pkp/lib/vendor/phpdocumentor/reflection-docblock					\
        lib/pkp/lib/vendor/doctrine/instantiator/tests						\
        lib/pkp/lib/vendor/sebastian/global-state/tests						\
        lib/pkp/lib/vendor/sebastian/comparator/tests						\
        lib/pkp/lib/vendor/sebastian/diff/tests							\
        lib/pkp/lib/vendor/oyejorge/less.php/test						\
        lib/pkp/js/lib/pnotify/build-tools							\
        lib/pkp/lib/vendor/alex198710/pnotify/.git						\
        node_modules										\
        .babelrc										\
        .editorconfig										\
        .eslintignore										\
        .eslintrc.js										\
        .postcssrc.js										\
        package.json										\
        webpack.config.js									\
        lib/ui-library"

RUN apk add --update --no-cache $PACKAGES && \
        ln -s /usr/bin/php7 /usr/bin/php && \
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
        # Configure and download code from git
        git config --global url.https://.insteadOf git:// && \
        git config --global advice.detachedHead false && \
        git clone --depth 1 --single-branch --branch $OMP_VERSION --progress https://github.com/pkp/omp.git . && \
        git checkout -q $OMP_VERSION  && \
        git submodule update --init --recursive >/dev/null && \
        # Install Composer Deps and NPM
        composer --working-dir=lib/pkp update --no-dev  && \
        composer --working-dir=plugins/paymethod/paypal update --no-dev && \
        npm install -y && npm run build && \
        # Clear the base project
        cp config.TEMPLATE.inc.php config.inc.php && \    
        rm -rf $EXCLUDE && \
        find . \( -name .gitignore -o -name .gitmodules -o -name .keepme \) -exec rm '{}' \;

# -----------------------------------------------------------------------------------------------------------------------------------
# RUNNING CONTAINER
# -----------------------------------------------------------------------------------------------------------------------------------
FROM php:7.2-alpine
LABEL maintainer="Lucas G. Diedrich <lucas.diedrich@gmail.com>"
WORKDIR /var/www/html
COPY --from=builder /tmp/ /var/www/html/

ENV OMP_VERSION="3_1_2-1"       \
        PKP_CLI_INSTALL="0"         \
        PKP_DB_HOST="localhost"     \
        PKP_DB_USER="omp"           \
        PKP_DB_PASSWORD="omp"       \
        PKP_DB_NAME="omp"           \
        PKP_WEB_CONF="/etc/apache2/conf.d/omp.conf" \
        PKP_CONF="/var/www/html/config.inc.php" \
        SERVERNAME="localhost" \
        HTTPS="on" \
        PACKAGES="supervisor dcron apache2 apache2-ssl apache2-utils file \
        php7-apache2 php7-zlib php7-json php7-phar php7-openssl \
        php7-curl php7-mcrypt php7-pdo_mysql php7-ctype php7-zip \
        php7-gd php7-xml php7-dom php7-iconv php7-mysqli php7-mbstring \
        php7-session php7-xml php7-simplexml php7-xsl"   

RUN echo ${PACKAGES}; apk add --update --no-cache $PACKAGES && \
        mkdir -p /var/www/files /run/apache2 /run/supervisord/ && \
        chown -R apache:apache /var/www/* && \
        sed -i -e '\#<Directory />#,\#</Directory>#d' /etc/apache2/httpd.conf && \
        sed -i -e "s/^ServerSignature.*/ServerSignature Off/" /etc/apache2/httpd.conf && \
        docker-php-ext-install mysqli && docker-php-ext-enable mysqli 

COPY files/ /
EXPOSE 80 443
VOLUME [ "/var/www/files", "/var/www/html/public" ]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

