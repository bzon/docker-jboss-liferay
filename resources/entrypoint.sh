#!/bin/bash

set -e 

mkdir -p /opt/jboss/deploy
# Do not apply automated changes in configuration files if /opt/vars.lock exist.
# Nice trick!
if [[ ! -f "/opt/vars.lock" ]]; then

    replacer() {
      replacement=$(env | grep $token | awk -F= '{print $2}')
      if [[ $(cat $FILE | grep "###$token###" | wc -l) -gt 0 ]]; then
        echo "File=$FILE, Token=###${token}###, Replacement=${replacement}"
        sed -i "s+###$token###+$replacement+g" $FILE
      fi
    }

    # Apply configuration for standalone.xml
    FILE=${JBOSS_HOME}/standalone/configuration/standalone.xml
    declare -a JBOSS_AS_ENVS=$(env | grep ^"JBOSS_AS_" | awk -F= '{print $1}')
    for token in ${JBOSS_AS_ENVS[@]}
    do
      replacer
    done

    # Apply configuration for portal-ext.properties
    FILE=/opt/jboss/portal-ext.properties
    declare -a PORTAL_EXT_ENVS=$(env | grep ^"PORTAL_EXT_" | awk -F= '{print $1}')
    for token in ${PORTAL_EXT_ENVS[@]}
    do
      replacer
    done

    # Apply changes liferay xml files using the default context root
    WEB_INF_DIR=$JBOSS_HOME/standalone/deployments/ROOT.war/WEB-INF
    declare -a FILES=( "$WEB_INF_DIR/jboss-web.xml" "$WEB_INF_DIR/jboss-web.xml.5" )
    for file in ${FILES[@]}
    do
      echo "File=$file, Context Root Replacement=${PORTAL_EXT_CONTEXT_ROOT}"
      sed -i "s+<context-root>.*+<context-root>${PORTAL_EXT_CONTEXT_ROOT}</context-root>+" $file
    done

fi

# If `docker run` received no additional arguments, then run jboss startup script.
if [[ $# -lt 1 ]]; then
  # If default Liferay JNDI is set,
  if [[ ! -z ${PORTAL_EXT_DEFAULT_DS_JNDI} ]]; then
    # Wait for database to be healthy
    /wait-for-it.sh ${JBOSS_AS_DB_HOST}:${JBOSS_AS_DB_PORT} --timeout=2000 --strict  -- echo "Database is ready for use!"
  else
    echo "[WARNING] You did not define a value for PORTAL_EXT_DEFAULT_DS_JNDI variable. Set it to 'java:jboss/LiferayPool' if you want to use an external database. Jboss will use the default built H2 for now.."
    # Remove default jndi settings as it can cause errors if empty.
    sed -i "s+jdbc.default.driverClassName=.*++" /opt/jboss/portal-ext.properties
    sed -i "s+jdbc.default.jndi.name=.*++" /opt/jboss/portal-ext.properties
  fi
  # Start Jboss
  /opt/jboss/startup.sh
fi

# Execute whatever argument was passed like `bash`
exec "$@"
	
