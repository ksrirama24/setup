#!/bin/bash
#
# 21-Oct-2016 : ksrirama - Initial Version
#
#
#
#
################################################################
#
### Usage function
#
usage()
{

        echo "
Usage :
./3_install_DMS.sh [-help] [-dmsTop=<DMS_TOP location>] [-mongoHost=<MongoDB Hostname>] [-mongoPort=<MongoDB Port>] [-mongoDbName=<MongoDB Repository Name>] [-mongoUser=<MongoDB Username>] [-mongoSSL=<true or false>] [-silent] [-propFile=<properties file>] [-releaseLocation=<Release bits location>] [-dmsHost=<DMS hostname>] [-useWildCard=<Wildcard domain name>] [-sslSanExt=<Ext for SSL certification generation>]

Where:
dmsTop           : Top level directory for DMS -- Default location :  $HOME/PFS/TEST
dmsHost          : DMS hostname (used for creating SSL certificate)-- Default location :  $HOME/PFS/TEST
isSSL            : Enable SSL for wildfly ? (true or false) -- Default : true
useWildCard      : Wildcard Domain name to be used for SSL for wildfly -- Default : Hostname
sslSanExt        : Extension values to be used for SSL for wildfly -- Default : IP Address
mongoHost        : Hostname where MongoDB is installed - Default : NONE
mongoPort        : Port number where MongoDB is running on - Default : 27017
mongoDbName      : MongoDB Database name used for DMS repository - Default : dmsrepo
mongoUser        : MongoDB Username for DMS repository - Default : dmsuser
mongoUserPass    : MongbDB Username Password (in AES encryption value)- Default : admin
mongoSSL         : Is MongoDB running in SSL? (true or false) Default : true
releaseLocation  : Release bits location -- Default : NONE
propFile         : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.
silent           : Do not prompt for inputs, use default values

Eg:
./3_install_DMS.sh

./3_install_DMS.sh -propFile=/path/to/env.properties

./3_install_DMS.sh -pfsHome=/path/to/PFS/79212

./3_install_DMS.sh -pfsHome=/home/dh/PFS/TEST -mongoHost=192.168.4.88  -mongoPort=27017 -mongoDbName=dmsrepo -mongoUser=dmsuser -mongoUserPass=admin

./3_install_DMS.sh -pfsHome=/home/dh/PFS/TEST -mongoHost=192.168.4.88  -mongoPort=27017 -mongoDbName=dmsrepo

Note:
The script needs to be run in bash shell

"
}



#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=${1#${PARAM}=}
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -propFile)
            propFile=$VALUE
            ;;
        -releaseLocation)
            releaseLocation=$VALUE
            ;;
        -isSSL)
            isSSL=$VALUE
            ;;
        -dmsTop)
            dmsTop=$VALUE
            ;;
        -mongoPort)
            mongoPort=$VALUE
            ;;
        -mongoHost)
            mongoHost=$VALUE
            ;;
        -mongoDbName)
            mongoDbName=$VALUE
            ;;
        -mongoSSL)
            mongoSSL=$VALUE
            ;;
        -silent)
            silent="true"
            ;;
        -mongoUser)
            mongoUser=$VALUE
            ;;
        -mongoUserPass)
            mongoUserPass=$VALUE
            ;;
        *)
            echo 
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift

done

echo
echo
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		DMS Tier Installation Script"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
#
### BEGIN
#
date=`date`
echo 
echo "Script start time : $date"
echo


#####################################################################################
#
# Common Functions
#
####################################################################################
dirName=`dirname $0`

PWD=`pwd`

### For absolute PATH
echo "$dirName" | grep ^/ > /dev/null

if  [ $? -eq 0 ]
then
        scriptDir=$dirName
elif [ $dirName == "." ]
then
        scriptDir="$PWD"
else
        scriptDir=`cd ${PWD}/${dirName}; pwd`
fi



if [ ! -f ${scriptDir}/lib/commonFunctions.lib ]
then
	echo
	echo "ERROR : Common functions file commonFunctions.lib is NOT FOUND."
	echo
	exit 1
fi

. ${scriptDir}/lib/commonFunctions.lib

checkBash

####################################################################################

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

echo
echo
echo "Using PATH : $PATH"
echo
echo

### If properties file is provided, get the values from there

if [ "x${propFile}" != "x" ] && [ -r $propFile ]
then

        echo
        echo "Properties file is provided, let us read the environment details from there."
        echo

        if [ "x${releaseLocation}" == "x" ]
        then
                getKeyValue "${propFile}" "release.bits.loc"
                releaseLocation=$value
        fi

        if [ "x${dmsHost}" == "x" ]
        then
		hostname=`hostname`
                getKeyValue "${propFile}" "dms.hostname" "$hostname"
                dmsHost=$value
        fi


        if [ "x${dmsTop}" == "x" ]
        then
                getKeyValue "${propFile}" "dms.top" 
                dmsTop=$value
        fi

        if [ "x${isSSL}" == "x" ]
        then
                getKeyValue "${propFile}" "dms.ssl" "true"
                isSSL=$value
        fi

        if [ "x${mongoHost}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.hostname"
                mongoHost=$value
        fi

        if [ "x${mongoPort}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.port" "27017"
                mongoPort=$value
        fi

        if [ "x${mongoSSL}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.ssl" "true"
                mongoSSL=$value
        fi

        if [ "x${mongoDbName}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.name" "dmsrepo"
                mongoDbName=$value
        fi

        if [ "x${mongoUser}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.username" "dmsuser"
                mongoUser=$value
        fi

        if [ "x${mongoUserPass}" == "x" ]
        then
                getKeyValue "${propFile}" "mongodb.password" "admin"
                mongoUserPass=$value
        fi

        if [ "x${useWildCard}" == "x" ]
        then
                getKeyValue "${propFile}" "dms.ssl.wildcard" "${hostname}"
                useWildCard=$value
        fi

        if [ "x${sslSanExt}" == "x" ]
        then
### Get the IP Address of the machine, this is needed to generate the machine specific certificate
		ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
                getKeyValue "${propFile}" "dms.ssl.san.ext" "ip:${ipAddress}"
                sslSanExt=$value
        fi


### It is silent mode if properties file is used
        silent="true"
fi



if [ "x${silent}" = "x" ]
then
        silent="false"
fi

echo
echo "Using the following details :"
echo
echo "DMS_TOP : $dmsTop"
echo
echo "DMS SSL : $isSSL"
echo
echo "MongoDB Host : $mongoHost"
echo
echo "MongoDB Port : $mongoPort"
echo
echo "MongoDB Name : $mongoDbName"
echo
echo "MongoDB SSL : $mongoSSL"
echo
echo "MongoDB Username : $mongoUser"
echo
echo "MongoDB Password : $mongoUserPass"
echo
echo


### Let us unzip the JDK first

javaZip="${releaseLocation}/MISC/jdk-8u72-linux-x64.tar.gz"

if [ ! -r $javaZip ]
then
	echo
	echo "ERROR : Unable to read $javaZip";
	echo
	exit 1
fi

### Yeh. Found javaZip, let us unzip under /opt/java

javaTop="$dmsTop"
javaHome="${javaTop}/jdk1.8.0_72"

echo
echo "Found $javaZip, unzipping under ${javaTop} ....."
echo



backupFile $javaHome 

runCmd "mkdir -p $javaTop"

runCmd "tar -zxf $javaZip -C $javaTop"


### Now unzip the DMS wildfly

wildflyZip="${releaseLocation}/MISC/wildfly-8.2.0.Final.tar.gz"
wildflyZip="${releaseLocation}/MISC/wildfly-8.2.0.zip"

if [ ! -r $wildflyZip ]
then
	echo
	echo "ERROR : Unable to read $wildflyZip";
	echo
	exit 1
fi


### Yeh. Found wildflyZip, let us unzip under /opt

dmsHome="${dmsTop}/wildfly-8.2.0"

#backupFile $dmsHome 

echo
echo "Found $wildflyZip, unzipping under $dmsTop ....."
echo


#runCmd "tar -xzf $wildflyZip -C $dmsTop"
runCmd "unzip -qod $dmsTop $wildflyZip"


### Create DMSconfiguration.properties
###############################################################################################################

echo
echo
echo "Updating dms-configiration.properties file....."
echo

dmsConfFile="${dmsHome}/standalone/configuration/dms-configuration.properties"
dmsConfFileUpdated="/tmp/dms-configuration.properties"

runCmd "rm -f $dmsConfFileUpdated"

if [ "${mongoSSL}" == "true" ]
then
	mongoConnStr="mongodb://${mongoUser}:${mongoUserPass}@${mongoHost}:${mongoPort}/${mongoDbName}?ssl=true"
else
	mongoConnStr="mongodb://${mongoUser}:${mongoUserPass}@${mongoHost}:${mongoPort}/${mongoDbName}"
fi


echo "
# DMS Configuration file

# DMS AES encryption related properties
keystore.filename=sso-aes256-keystore.jck
keystore.password=dhi\$123
alias.name=ssoaes256
key.password=dhi\$123
initial.iv=1111100010011111

RestEnabled=false
mongo.connection.uri=$mongoConnStr
mongodbname=$mongoDbName
" > $dmsConfFileUpdated

echo
runCmd "cp $dmsConfFileUpdated $dmsConfFile"
echo


runCmd "rm -f $dmsConfFileUpdated"




### No need to check if wildfly group/user exists, if it exists, the command does not run and fails. So let us run it straight away

#runCmd "addgroup wildfly"

#runCmd "$sudo useradd -g wildfly wildfly"

#runCmd "$sudo chown -R wildfly:wildfly $dmsHome"


#runCmd "$sudo ln -s $dmsHome /opt/wildfly"

#runCmd "$sudo chown -R dh:dh $dmsHome"

#echo
#echo "Creating the user for Wildfly administration....."
#echo

export JAVA_HOME=$javaHome
export PATH=$JAVA_HOME/bin:$PATH

echo
which java
echo

echo "JAVA_HOME=$JAVA_HOME"
echo "PATH=$PATH"
#runCmd "${dmsHome}/bin/add-user.sh"

echo 
echo "Starting SSL Configurations ..... "
echo


echo
echo "Generating identity.jks file ....."
echo


echo
which keytool
echo


identityJksFile="${dmsTop}/identity.jks"


backupFile $identityJksFile

which keytool

#cmd="${JAVA_HOME}/bin/keytool -genkey -keyalg RSA -sigalg SHA256withRSA -keystore $identityJksFile -keysize 2048 -alias dms -keypass password -storepass password -validity 3650 -dname \"CN=${hostname}, OU=PiiE Engine, O=Digital Harbor, L=Provo, S=UT, C=US\" -ext san=ip:${ipAddress}"
cmd="${JAVA_HOME}/bin/keytool -v -genkey -keyalg RSA -sigalg SHA256withRSA -keystore $identityJksFile -keysize 2048 -alias dmskey -keypass password -storepass password -validity 3650 -dname \"CN=${hostname}, OU=PiiE Engine, O=Digital Harbor, L=Provo, S=UT, C=US\" -ext san=${sslSanExt}"

echo
echo "Running the command : $cmd"

echo $cmd > /tmp/${datestamp}.sh
chmod 755 /tmp/${datestamp}.sh
/tmp/${datestamp}.sh
RC=$?
echo "Done."

echo
echo "Copying $identityJksFile to ${dmsHome}/standalone/configuration"
runCmd "cp $identityJksFile ${dmsHome}/standalone/configuration"
echo


echo
echo "Export dms KEY to a certificate."
echo

clientCerFile="${dmsTop}/client_DMS.cer"

runCmd "${JAVA_HOME}/bin/keytool -export -alias dmskey -file ${clientCerFile} -keystore ${identityJksFile} -storepass password"

echo
echo "Import the client_DMS.cer to JDK 1.8 used by DMS"
echo

runCmd "${JAVA_HOME}/bin/keytool -v -import -noprompt -trustcacerts -alias dmskey -file ${clientCerFile} -keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit"

echo "Note:"
echo "====="
echo "	Copy the $clientCerFile to the PFS machine and import into <JAVA_HOME>/jre/lib/security/cacerts"
echo





echo
echo "Creating the startup script that can be used to start DMS Wildfly server....."
echo

startupScript="${dmsHome}/bin/start.sh"
echo "export JAVA_HOME=${JAVA_HOME}" > $startupScript
echo "sh standalone.sh -b 0.0.0.0" >> $startupScript
#echo "sh standalone.sh -Djsse.enableCBCProtection=false -b 0.0.0.0" >> $startupScript
runCmd "chmod 755 $startupScript"
echo "Use the script $startupScript to start the server."
echo
echo



echo "Environment Details :"
echo "====================="
echo
echo "JAVA_HOME : $javaHome"
echo
echo "DMS JBoss Home : $dmsHome"
echo
echo "Startup script : $startupScript"
echo "Command : "
cat $startupScript
echo




#
### END
#
date=`date`
echo 
echo "Script end time : $date"
echo


echo
### Now exit gracefully
exit 0
