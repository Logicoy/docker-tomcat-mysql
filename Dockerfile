FROM openjdk:8u212-jdk
MAINTAINER Nageswara Rao Samudrala <nageswara.samudrala@logicoy.com>

ENV TOMCAT_MAJOR_VERSION=9
ENV TOMCAT_VERSION=9.0.22
ENV TOMCAT_HOME=/opt/apache-tomcat-$TOMCAT_VERSION
ENV OPENEMPI_HOME=/opt/openempi
ENV OPENEMPI_CONFIG=/opt/openempi/conf


# Install mysql-server and tomcat 9
RUN apt-get update && apt-get install -y lsb-release && \
  wget https://dev.mysql.com/get/mysql-apt-config_0.8.4-1_all.deb && \
  dpkg -i mysql-apt-config_0.8.4-1_all.deb && rm -f mysql-apt-config_0.8.4-1_all.deb && \
  mkdir -p $TOMCAT_HOME && cd /opt && \
  wget https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
  tar -xvf apache-tomcat-$TOMCAT_VERSION.tar.gz && rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

# Install packages
RUN apt-get update && \
  apt-get -y install mysql-server pwgen supervisor && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add image configuration and scripts
ADD start-tomcat.sh /start-tomcat.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-tomcat.conf /etc/supervisor/conf.d/supervisord-tomcat.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD mysql-setup.sh /mysql-setup.sh
RUN chmod 755 /*.sh

WORKDIR $TOMCAT_HOME

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 8080 3306

COPY conf/ $OPENEMPI_HOME/conf/
CMD cd $OPENEMPI_HOME
CMD touch openempi.log
CMD chmod 755 openempi.log
COPY webapp-web/target/openempi-admin.war /opt/apache-tomcat-$TOMCAT_VERSION/webapps/openempi-admin.war


ENTRYPOINT ["/run.sh"]
