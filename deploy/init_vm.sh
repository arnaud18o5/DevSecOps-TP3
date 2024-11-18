#!/bin/bash

# Mettre à jour les paquets
sudo apt update

# Installer PHP et les extensions nécessaires
sudo apt install -y php
sudo apt install -y php-{cli,curl,mbstring,xml,zip,gd}

PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
sudo apt install -y php${PHP_VERSION}-fpm
sudo systemctl start php${PHP_VERSION}-fpm
sudo systemctl enable php${PHP_VERSION}-fpm

sudo systemctl restart apache2

# Installer Composer si ce n'est pas déjà fait
if [ ! -f /usr/local/bin/composer ]; then
    # Télécharger le script d'installation de Composer
    curl -sS https://getcomposer.org/installer -o composer-setup.php

    # Vérifier l'intégrité du script d'installation
    HASH=$(curl -sS https://composer.github.io/installer.sig)
    if php -r "exit(hash_file('SHA384', 'composer-setup.php') === '$HASH' ? 0 : 1;"; then
    echo "Installer verified"
    else
    echo "Installer corrupt"
    rm composer-setup.php
    exit 1
    fi

    # Installer Composer
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
fi

# Cloner le dépôt Git et configurer le projet
cd ~
if ! [ -d prod ]; then
    git clone https://github.com/arnaud18o5/DevSecOps-TP3.git
    mv DevSecOps-TP3/ prod
    cd prod/
    git config pull.rebase false  # merge
fi

# Setup du DocumentRoot d'Apache
# Variables
USER_HOME="/home/ubuntu"
PROJECT_DIR="${USER_HOME}/prod/public"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

if grep -q "DocumentRoot" "$APACHE_CONF"; then
    sed -i "s|DocumentRoot .*|DocumentRoot $PROJECT_DIR|" "$APACHE_CONF"
else
    echo "DocumentRoot $PROJECT_DIR" >> "$APACHE_CONF"
fi

# Permissions
chown -R www-data:www-data "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

# Redémarrage des services
sudo systemctl restart php${PHP_VERSION}-fpm
sudo systemctl restart apache2

echo "Installation terminée avec succès !"
