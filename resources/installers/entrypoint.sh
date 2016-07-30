#!/bin/bash

set -e

if [[ -n $MANAGEMENT_BIND_IP_ADDRESS ]]; then
    sed -i -e 's/jboss.bind.address.management:127.0.0.1/jboss.bind.address.management:'"$MANAGEMENT_BIND_IP_ADDRESS"'/g' $JBOSS_HOME/standalone/configuration/standalone-ha.xml
echo a
fi

if [[ -n $SQL_POOL_NAME ]]; then
    sed -i -e 's/jndi-name="java:jboss\/datasources\/ExampleDS" pool-name="ExampleDS"/jndi-name="java:jboss\/datasources\/'"$SQL_POOL_NAME"'" pool-name="'"$SQL_POOL_NAME"'"/g' $JBOSS_HOME/standalone/configuration/standalone-ha.xml
echo b
fi

if [[ -n $SQL_HOST_NAME ]]; then
    sed -i -e 's/<connection-url>jdbc:mysql:\/\/localhost\/lportal<\/connection-url>/<connection-url>jdbc:mysql:'"$SQL_HOST_NAME"'<\/connection-url>/g' $JBOSS_HOME/standalone/configuration/standalone-ha.xml
echo c
fi

chown -R 1000:1000 /opt/jboss
su jboss -c /opt/jboss/jboss.sh
