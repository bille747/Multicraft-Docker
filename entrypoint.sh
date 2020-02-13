#!/bin/bash

# Set umask for Unraid
umask 000

NEWINSTALL=0

# Create the multicraft folders that will be persistent
mkdir -p /multicraft/jar
mkdir -p /multicraft/data
mkdir -p /multicraft/servers
mkdir -p /multicraft/templates
mkdir -p /multicraft/configs

# Change multicraft owner to nobody:users
chown -R nobody:users /multicraft/


#######

## Multicraft Daemon Config

#######
if [ ! -f /multicraft/configs/multicraft.conf ]; then
    NEWINSTALL=1
    echo "[$(date +%Y-%m-%d_%T)] - No multicraft daemon config file detected, creating new one from multicraft.conf.dist"
    cp -f /opt/multicraft/multicraft.conf.dist /multicraft/configs/multicraft.conf

    # Update multicraft config file with docker variables
    sed -i -E "s|^user\s=\s(\S*)|user = nobody:users|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#password\s=\s(\S*)|password = ${daemonpwd}|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#id\s=\s(\S*)|id = ${daemonid}|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#allowSymlinks\s=\s(\S*)|allowSymlinks = true|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpPasvPorts\s=\s(\S*)|ftpPasvPorts = 6000-6005|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpNatIp\s=\s(\S*)|ftpNatIp = ${FTPNatIP}|" /multicraft/configs/multicraft.conf
    if [ "$dbengine" == "mysql" ]; then
        sed -i -E "s|^#database\s=\s(m\S*)|database = mysql:host=${mysqlhost};dbname=${mysqldbname}|" /multicraft/configs/multicraft.conf
        sed -i -E "s|^#dbUser\s=\s(\S*)|dbUser = ${mysqldbuser}|" /multicraft/configs/multicraft.conf
        sed -i -E "s|^#dbPassword\s=\s(\S*)|dbPassword = ${mysqldbpass}|" /multicraft/configs/multicraft.conf
    elif [ "$dbengine" == "sqlite" ]; then
        sed -i -E "s|^#database\s=\s(s\S*)|database = sqlite:daemon.db|" /multicraft/configs/multicraft.conf
    else
        echo "[$(date +%Y-%m-%d_%T)] - No database engine specified. Please edit config files manually."
    fi
    sed -i -E "s|^baseDir\s=\s(\S*)|baseDir = /opt/multicraft|" /multicraft/configs/multicraft.conf
    sed -i -E "s|^#ftpIp\s=\s(\S*)|ftpIp = 0.0.0.0|" /multicraft/configs/multicraft.conf

    # Copy config file to the Multicraft folder
    install -C -o nobody -g users /multicraft/configs/multicraft.conf /opt/multicraft/multicraft.conf
else
    echo "[$(date +%Y-%m-%d_%T)] - Multicraft daemon config file already exist! Installing config file."
    install -C -o nobody -g users /multicraft/configs/multicraft.conf /opt/multicraft/multicraft.conf
fi

#######

## Multicraft Panel Config

#######
if [ ! -f /multicraft/configs/panel.php ]; then
    echo "[$(date +%Y-%m-%d_%T)] - No Multicraft Panel config file found. Creating new one from config.php.dist";
    cp -f /var/www/html/protected/config/config.php.dist /multicraft/configs/panel.php

    if [ "$dbengine" == "mysql" ]; then
        # Set Panel settings.
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db_pass' => '${mysqldbpass}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db_user' => '${mysqldbuser}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'panel_db'\s=>\s'(s\S*),/a 'panel_db' => 'mysql:host=${mysqlhost};dbname=${mysqldbname}'," /multicraft/configs/panel.php

        # Remove Panel SQLite settings
        sed -i -E "s|^\s*'panel_db'\s=>\s'(s\S*),||" /multicraft/configs/panel.php

        # Set daemon settings
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db_pass' => '${mysqldbpass}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db_user' => '${mysqldbuser}'," /multicraft/configs/panel.php
        sed -i -E "/^\s*'daemon_db'\s=>\s'(s\S*),/a 'daemon_db' => 'mysql:host=${mysqlhost};dbname=${mysqldbname}'," /multicraft/configs/panel.php

        # Remove Daemon SQLite settings
        sed -i -E "s|^\s*'daemon_db'\s=>\s'(s\S*),||" /multicraft/configs/panel.php

    elif [ "$dbengine" == "sqlite" ]; then
        sed -i -E "s|^\s*'panel_db'\s=>\s'(\S*),|'panel_db' => 'sqlite:/multicraft/data/panel.db',|" /multicraft/configs/panel.php
        sed -i -E "s|^\s*'daemon_db'\s=>\s'(\S*),|'daemon_db' => 'sqlite:/multicraft/data/daemon.db',|" /multicraft/configs/panel.php
    else
        echo "[$(date +%Y-%m-%d_%T)] - No database engine specified. Please edit config files manually."
    fi

    sed -i -E "s|^\s*'daemon_password'\s=>\s'(\S*),|'daemon_password' => '${daemonpwd}',|" /multicraft/configs/panel.php

    # Copy config file to the panel folder.
    chown nobody:users /multicraft/configs/panel.php
    chmod 777 /multicraft/configs/panel.php
    ln -s /multicraft/configs/panel.php /var/www/html/protected/config/config.php
    #install -C -o www-data -g www-data /multicraft/configs/panel.php /var/www/html/protected/config/config.php

else
    echo "[$(date +%Y-%m-%d_%T)] - Multicraft Panel config file found. Creating symbolic link"
    chown nobody:users /multicraft/configs/panel.php
    chmod 777 /multicraft/configs/panel.php
    ln -s /multicraft/configs/panel.php /var/www/html/protected/config/config.php
fi

# Start apache2
service apache2 start

# If new install
if [ "$NEWINSTALL" == 1 ]; then

    cp -r /opt/multicraft/jar/* /multicraft/jar
    chown -R nobody:users /multicraft/jar

    cp -r /opt/multicraft/templates/* /multicraft/templates
    chown -R nobody:users /multicraft/templates

    rm -r /opt/multicraft/jar
    rm -r /opt/multicraft/templates

else
    # Remove install.php since it is not needed.
    rm /var/www/html/install.php
fi

# Remove data folder to replace with symlink
rm -r /opt/multicraft/data
ln -s /multicraft/data /opt/multicraft/data

rm -r /opt/multicraft/jar
ln -s /multicraft/jar /opt/multicraft/jar

rm -r /opt/multicraft/servers
ln -s /multicraft/servers /opt/multicraft/servers

rm -r /opt/multicraft/templates
ln -s /multicraft/templates /opt/multicraft/templates

# Start and stop Multicraft to set permissions
/opt/multicraft/bin/multicraft start
sleep 1

# Set data folder permissions
chmod -R 777 /multicraft

# Tail the multicraft logs
tail -f /opt/multicraft/multicraft.log

