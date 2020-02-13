FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive

# Configure user nobody to match unRAID's settings
RUN usermod -u 99 nobody 
RUN usermod -g 100 nobody 
RUN usermod -d /home nobody 
RUN usermod -a -G users www-data
RUN chown -R nobody:users /home

# Install Dependencies
RUN apt-get update -q && apt-get install -qy \
    apache2 \
    php \
    wget \
    php-mysql \
    php-sqlite3 \
    php-gd \
    sudo \
    zip \
    unzip \
    openjdk-11-jre \
    && rm -rf /var/lib/apt/lists/*

# Download the latest version of multicraft and extract it.
RUN wget http://www.multicraft.org/download/linux64 -O /tmp/multicraft.tar.gz && \
    tar xvzf /tmp/multicraft.tar.gz -C /tmp && \
    rm /tmp/multicraft.tar.gz

# Copy Apache2 config file
COPY apache.conf /etc/apache2/sites-enabled/000-default.conf

# Run the install script
RUN mkdir -p /scripts/
COPY install.sh /scripts/install.sh
RUN chmod +x /scripts/install.sh && \
    /scripts/install.sh

# Deploy the Entrypoint script
COPY entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

# Exposed ports and Volumes required
EXPOSE 80
EXPOSE 21
EXPOSE 25565
EXPOSE 19132-19133/udp
EXPOSE 25565/udp
EXPOSE 6000-6005
VOLUME [ "/multicraft" ]

# Daemon Variables
ENV daemonpwd=none 
ENV daemonid=1


# Database Variables
ENV dbengine=sqlite
ENV mysqlhost=192.168.2.2
ENV mysqldbname=multicraft
ENV mysqldbuser=multicraft
ENV mysqldbpass=multicraft

# FTP Variables
ENV FTPNatIP=192.168.2.2

# Run the entrypoint script
CMD [ "/scripts/entrypoint.sh" ]