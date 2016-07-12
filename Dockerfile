FROM bzon/jboss-eap:v6.4.0-ga

# Switch to root, to have the permission to delete resources in /tmp and do stuffs that might requires sudo
USER root

# Set Docker build variables
ARG liferay_dependencies_version=liferay-portal-dependencies-6.2-ee-sp12
ARG liferay_war=liferay-portal-6.2-ee-sp12-20150804162203131.war
ARG mysql_connector_jar=mysql-connector-java-5.1.39-bin.jar
ARG liferay_module_dir=$JBOSS_HOME/modules/com/liferay/portal/main

# Copy Liferay installer and dependencies
COPY resources/installers /tmp/installers
COPY resources/conf /tmp/conf

# Install ifconfig
RUN yum -y install net-tools; yum clean all

# Configure liferay module
RUN mkdir -p ${liferay_module_dir} && \
    cp /tmp/conf/com.liferay.portal.module.xml ${liferay_module_dir}/module.xml && \
    unzip /tmp/installers/${liferay_dependencies_version}.zip -d /tmp/ && \
    cp /tmp/${liferay_dependencies_version}/** ${liferay_module_dir}/ && \
    cp /tmp/installers/${mysql_connector_jar} ${liferay_module_dir}

# Configure Jboss standalone startup configuration
RUN yes | cp /tmp/conf/standalone.xml.template $JBOSS_HOME/standalone/configuration/standalone.xml && \
    cp /tmp/conf/server.policy $JBOSS_HOME/bin/server.policy && \
    yes | cp /tmp/conf/standalone.conf $JBOSS_HOME/bin/standalone.conf

# Prepare liferay deployment
RUN mkdir -p $JBOSS_HOME/standalone/deployments/ROOT.war && \
    cd $JBOSS_HOME/standalone/deployments/ROOT.war; jar -xvf /tmp/installers/${liferay_war} && \
    rm -fr $JBOSS_HOME/standalone/deployments/ROOT.war/WEB-INF/lib/eclipselink.jar && \
    cp /tmp/conf/portal-ext.properties.template /opt/jboss/portal-ext.properties && \
    cp /tmp/installers/tomcat-juli.jar $JBOSS_HOME/standalone/deployments/ROOT.war/WEB-INF/lib/ && \
    touch $JBOSS_HOME/standalone/deployments/ROOT.war.dodeploy
  
# Clean up Step before switch user
RUN chown -R 1000:1000 /opt/jboss && \
    rm -fr /tmp/**

VOLUME ["/opt/jboss"]

# Switch back to jboss user
USER jboss

# Every variables starting with JBOSS_AS_ has a corresponding token in standalone.xml
# e.g: JBOSS_AS_MYSQL_USER has a token of ###JBOSS_AS_MYSQL_USER### see resources/conf/standalone.xml for more info
ENV JBOSS_AS_MYSQL_DS_JNDI="java:jboss/LiferayPool" \
    JBOSS_AS_MYSQL_DS_POOL="LiferayPool" \
    JBOSS_AS_MYSQL_HOST="liferay-mysql" \
    JBOSS_AS_MYSQL_PORT="3306" \
    JBOSS_AS_MYSQL_DATABASE="lportal_db" \
    JBOSS_AS_MYSQL_USER="lportal" \
    JBOSS_AS_MYSQL_PASSWORD="lportal" \
    JBOSS_AS_DEPLOY_TIMEOUT="300"

# Every variables starting with PORTAL_EXT_ has a corresponding token in portal-ext.properties
# e.g: PORTAL_EXT_CONTEXT_ROOT has a token of ###PORTAL_EXT_CONTEXT_ROOT### see resources/conf/portal-ext.properties for more info
ENV PORTAL_EXT_CONTEXT_ROOT="/liferay" \
    PORTAL_EXT_DEFAULT_DS_JNDI="java:jboss/LiferayPool" \
    PORTAL_EXT_AUTO_DEPLOY_DIR="/opt/jboss/deploy"

# Set default environment variables for standalone.conf and standalone.sh
ENV STANDALONE_SCRIPT_ARGS="-c standalone.xml" \
    MGMT_BLOCKING_TIMEOUT="900" \
    JVM_XMX_SIZE="2048m" \
    JVM_XMS_SIZE="2048m" \
    JVM_MAX_PERM_SIZE="1024m" \
    USER_TIMEZONE="GMT" \
    JAVA_OPTS='-Dfile.encoding=UTF-8 -Djava.net.preferIPv4Stack=true -Djava.security.policy=$JBOSS_HOME/bin/server.policy -Djboss.home.dir=$JBOSS_HOME -Duser.timezone=${USER_TIMEZONE} -Xmx${JVM_XMX_SIZE} -Xms${JVM_XMS_SIZE} -XX:MaxPermSize=${JVM_MAX_PERM_SIZE} -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -Djboss.modules.policy-permissions=true -Djboss.as.management.blocking.timeout=$MGMT_BLOCKING_TIMEOUT'

EXPOSE 8443 8080 9990 9999 8125

COPY resources/entrypoint.sh /entrypoint.sh
COPY resources/wait-for-it.sh /wait-for-it.sh

ENTRYPOINT ["/entrypoint.sh"]
