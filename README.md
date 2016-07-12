# Quick Start Guide

## Requirement  

Your *Subscription license file* for Liferay Enterprise 6.2 e.g *your_license_file.xml*. Without this you will not be able to proceed with the Liferay startup wizard.

## Using Docker basic commands  

  - Create a docker bridge network:
    
     ```bash
     docker network create liferay-network
     ```
  - Deploy MySQL:

    ```bash
    docker run -d --net=liferay-network \
           --name=liferay-mysql \
           -p 3306:3306 \
           -e MYSQL_ROOT_PASSWORD="root" \
           -e MYSQL_USER="lportal" \
           -e MYSQL_PASSWORD="lportal" \
           -e MYSQL_DATABASE="lportal_db" -d mysql:5.7
    ```
    
  - Deploy Liferay:

    Increase the JVM_XMX_SIZE and JVM_XMS_SIZE to your preference.

    ```bash
    docker run -d --net=liferay-network \
              --name=liferay \
              -p 8080:8080 \
              -p 9990:9990 \
              -e JVM_XMX_SIZE="4096m" \
              -e JVM_XMS_SIZE="2048m" \
              -e PORTAL_EXT_CONTEXT_ROOT="/liferay" \
              -e JBOSS_AS_MYSQL_USER="lportal" \
              -e JBOSS_AS_MYSQL_PASSWORD="lportal" \
              -e JBOSS_AS_MYSQL_DATABASE="lportal_db" \
              bzon/jboss-liferay:6.2-ee-sp12
     ```

## Using Docker Compose command  

From the project workspace parent directory. Do the following:

  - Run:
 
      ```bash
      docker-compose up -d
      ```
  - Observe the logs:
 
     ```bash
     docker-compose logs
     ```

## Your Access Information  

Description | Value
------------ | -------------
Liferay Application URL | *http://localhost:8080/liferay*  
Jboss Management Console | *http://localhost:9990/console*  
Jboss Administrator | *admin*  
Jboss Administrator Password | *admin123!*  

The page should display some Licensing issue and that you'll need to enter your Order ID.

![LiferayHome](https://raw.githubusercontent.com/bzon/docker-jboss/master/jboss-liferay/6.4.0-GA/img/no-license.png)

## Enabling License

  - Copy your license file inside the running Liferay container:

    ```bash
    # **docker cp** will copy the license.xml as root by default
    docker cp license.xml liferay:/tmp/
    ```
  
  - Transfer the license file to the deploy directory as jboss user:
  - 
    ```bash
    docker exec -it liferay cp /tmp/license.xml /opt/jboss/deploy/ 
    ```

  - Observe the logs to see that the license file has been deployed successfully.
  
    ```bash
    docker exec -it liferay cat  /opt/jboss/logs/liferay.$(date +%Y-%m-%d).log
    16:36:45,270 INFO  [com.liferay.portal.kernel.deploy.auto.AutoDeployScanner][AutoDeployDir:204] Processing license.xml
    16:36:45,276 INFO  [com.liferay.portal.kernel.deploy.auto.AutoDeployScanner][LicenseAutoDeployListener:?] Copying license for /opt/jboss/deploy/license.xml
    16:36:45,308 INFO  [com.liferay.portal.kernel.deploy.auto.AutoDeployScanner][LicenseManager:?] Portal Development license validation passed
    16:36:45,308 INFO  [com.liferay.portal.kernel.deploy.auto.AutoDeployScanner][LicenseDeployer:?] License registered
    ``` 

If successful, access the page again and you should now be able to proceed with the Liferay Wizard.  

![LiferayHome](https://raw.githubusercontent.com/bzon/docker-jboss/master/jboss-liferay/6.4.0-GA/img/with-license.png)

# Building your own Docker Image

The Dockerfile was based from following this [Liferay installation guide for Liferay 6.2 on Jboss 7 AS] (https://dev.liferay.com/discover/deployment/-/knowledge_base/6-2/installing-liferay-on-jboss-7-1).  

This image will be built on top of a base Jboss image `bzon/jboss-eap:6.4.0-ga` from Docker hub. For more information about this build, please see [My Jboss EAP 6.4.0 Docker Project](https://github.com/bzon/docker-jboss/tree/master/jboss-eap-6.4).

## Requirements

Directory and Files tree.

```bash
Dockerfile
resources/
|__entrypoint.sh
|__wait-for-it.sh
|__instalers/
   |__ liferay-portal-6.2-ee-sp12-20150804162203131.war
   |__ liferay-portal-dependencies-6.2-ee-sp12.zip
   |__ mysql-connector-java-5.1.39-bin.jar
   |__ tomcat-juli.jar
|__conf/
   |__ portal-ext.properties.template
   |__ server.policy
   |__ standalone.conf
   |__ standalone.xml.template
   |__ com.liferay.portal.module.xml
```

## Artifacts 

All of the artifacts in this table should be present under the `resources/installers` directory.

Artifact | Download Source
------------ | -------------
liferay-portal-6.2-ee-sp12-20150804162203131.war | Liferay Subscription
liferay-portal-dependencies-6.2-ee-sp12.zip | Liferay Subscription
mysql-connector-java-5.1.39-bin.jar | http://dev.mysql.com/downloads/connector/j/
tomcat-juli.jar (optional) | http://www.java2s.com/Code/Jar/t/Downloadtomcatjulijar.htm
  
## Liferay and Jboss Configuration

Configuration File | Description
------------ | -------------
entrypoint.sh | Entrypoint script that orchestrates how the container will launch upon `docker run`
portal-ext.properties.template | A tokenised template of portal-ext.properties for Liferay related configurations.
server.policy | Jboss policy permission file.
standalone.conf | Jboss standalone.sh startup script's configuration for JAVA_OPTS.
standalone.xml.template | A tokenised template of Jboss standalone.sh configuration where Datasource and Liferay related stuffs are placed. This is passed as `-c standalone.xml` upon container launch by default.
com.liferay.portal.module.xml | Liferay dependencies module.xml file that corresponds with the Liferay dependencies from the Requirements table.

