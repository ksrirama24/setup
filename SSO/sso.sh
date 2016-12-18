#!/bin/bash


### Usage function
usage()
{
        echo "
Usage :
./sso.sh [-help] [-pfsHome=<pfs install location>] [-silent] [-ldapHost=<LDAP Hostname>] [-ldapPort=<LDAP Port>] [-ldapContainer=<LDAP container>] [-ldapDomain=<LDAP Domain>] [-ldapUsername=<LDAP Username>] [-ldapPassword=<LDAP Password>] [-portalIP=<Portal IP address>] [-portalPort=<Portal port number>] [-isSSL=<SSL flat (true/false)] [-serverType=<Server type for PSC to connect>] [hostedServer=<portal or enrollment>] [-propFile=<properties file>] [-ldapPasswordEnc=<Encrypted value for LDAP user password>]

Where:
pfsHome         : PFS Install location -- Default location :  $HOME/PFS/TEST
ldapHost        : LDAP Hostname [Default : 192.168.4.2]
ldapPort        : LDAP Port number [Default : 636]
ldapContainer   : LDAP Container [Default :  cn=users,dc=dhindia,dc=com]
ldapDomain      : LDAP Domain name [Default : dhindia.com]
ldapUsername    : LDAP username [Default : administrator]
ldapPassword    : LDAP username password [Default : Neomatrix@3]
ldapPasswordEnc : LDAP username password encrypted value - overrides ldapPassword [ Default : NONE ]
portalIP        : Portal port number [Default : Current machine IP]
portalPort      : Portal port number [Default : 8080]
isSSL           : Is SSL enabled in the environment (true/false) [Default : true]
serverType      : Required only for Enrollment, IF Multiple PSC exists, then specify this server PFS belongs to which type(PRD or UAT ) [Default : default]
hostedServer    : Specify whether the server is Enrollment or Portal server [Default : enrollment ]
silent          : Do not prompt for inputs, use default values
propFile        : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.

Eg:
./sso.sh -pfsHome=/home/dh/PFS/79212

./sso.sh -pfsHome=/home/dh/PFS/79212 -ldapHost=192.168.4.192 -ldapPort=666


Note:
The script needs to be run in bash shell

"

}


echo
echo
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		SSO Configuration script	"
echo "++++++++++++++++++++++++++++++++++++++++++++++++"
echo
#
### BEGIN
#
date=`date`
echo 
echo "Script start time : $date"
echo

rm -f /tmp/.tmpfile

#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=${1#${PARAM}=}
#    VALUE=`echo $1 | awk -F= '{print $2}'`
#    echo "echo $1 | sed 's+${PARAM}\=++g'" > /tmp/.tmpfile
#	chmod 755 /tmp/.tmpfile
#	VALUE=`/tmp/.tmpfile`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -propFile)
            propFile=$VALUE
            ;;
        -disable)
            disableSSO="true"
            ;;
        -isSSL)
            isSSL=$VALUE
            ;;
        -portalPort)
            portalPort=$VALUE
            ;;
        -portalIP)
            portalIP=$VALUE
            ;;
        -ldapPassword)
            ldapPassword=$VALUE
            ;;
        -ldapPasswordEnc)
            ldapPasswordEnc=$VALUE
            ;;
        -ldapUsername)
            ldapUsername=$VALUE
            ;;
        -ldapDomain)
            ldapDomain=$VALUE
            ;;
        -ldapContainer)
            ldapContainer=$VALUE
            ;;
        -ldapPort)
            ldapPort=$VALUE
            ;;
        -ldapHost)
            ldapHost=$VALUE
            ;;
        -mongoHost)
            mongoHost=$VALUE
            ;;
        -mongoPort)
            mongoPort=$VALUE
            ;;
        -mongoDbName)
            mongoDbName=$VALUE
            ;;
        -mongoUser)
            mongoUser=$VALUE
            ;;
        -mongoUserPass)
            mongoUserPass=$VALUE
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        -serverType)
            serverType=$VALUE
            ;;
        -hostedServer)
            hostedServer=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done
rm -f /tmp/.tmpfile


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


if [ ! -f ${scriptDir}/../lib/commonFunctions.lib ]
then
	echo
	echo "ERROR : Common functions file commonFunctions.lib is NOT FOUND."
	echo
	exit 1
fi

. ${scriptDir}/../lib/commonFunctions.lib

checkBash

####################################################################################

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

echo
echo
echo "Using PATH : $PATH"
echo
echo

if [ "x${propFile}" != "x" ] && [ -r $propFile ]
then

        echo
        echo "Properties file is provided, let us read the environment details from there."
        echo

        if [ "x${pfsHome}" == "x" ]
        then
                getKeyValue "${propFile}" "pfs.home"
                pfsHome=$value
        fi


        if [ "x${ldapHost}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.hostname"
                ldapHost=$value
        fi


        if [ "x${ldapPort}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.port" "636"
                ldapPort=$value
        fi

        if [ "x${ldapContainer}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.container"
                ldapContainer=$value
        fi

        if [ "x${ldapDomain}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.domain"
                ldapDomain=$value
        fi


        if [ "x${ldapUsername}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.username"
                ldapUsername=$value
        fi


        if [ "x${ldapPassword}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.password"
                ldapPassword=$value
        fi

        if [ "x${ldapPasswordEnc}" == "x" ]
        then
                getKeyValue "${propFile}" "ldap.password.encrypted" "x"
                ldapPasswordEnc=$value
        fi


        if [ "x${portalIP}" == "x" ]
        then
		ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
                getKeyValue "${propFile}" "sso.portal.ip" "$ipAddress"
                portalIP=$value
        fi

        if [ "x${portalPort}" == "x" ]
        then
                getKeyValue "${propFile}" "sso.portal.port" "8080"
                portalPort=$value
        fi

        if [ "x${isSSL}" == "x" ]
        then
                getKeyValue "${propFile}" "pfs.ssl" "true"
                isSSL=$value
        fi

        if [ "x${serverType}" == "x" ]
        then
                getKeyValue "${propFile}" "sso.server.type" "default"
                serverType=$value
        fi

        if [ "x${hostedServer}" == "x" ]
        then
                getKeyValue "${propFile}" "sso.hosted.server" "enrollment"
                hostedServer=$value
        fi

### Enable silent as properties file is passed
	silent="true"
fi






### Workaround for AWS QA LDAP

if [ "X${ldapPassword}" == "Xawsqaldappass" ]
then
                ldapPassword=")EBg6P&oLV9"
fi



if [ "x${pfsHome}" == "x" ]
then
	echo "Enter the PFS_HOME Location [Default : $HOME/PFS/TEST]:"
	read pfsHome
fi

echo
echo


### Use the default values in case still not provided
if [ "x${pfsHome}" == "x" ]
then
	pfsHome="$HOME/PFS/TEST"
	echo "INFO: PFS_HOME location is not provided, using the default location $pfsHome"
else
	echo "Using PFS_HOME location provided - $pfsHome"
fi



### Let us backup the files first
defaultCfg="${pfsHome}/jboss-5.1.0.GA/server/default/conf/default.cfg"
loginConfig="${pfsHome}/jboss-5.1.0.GA/server/default/conf/login-config.xml"
ssoWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/sso.war"
picketLinkWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/picketlink-sts-1.0.0.war"
userManagerFile="${pfsHome}/jboss-5.1.0.GA/server/default/conf/usermanager.properties"
connectorPropFile="${pfsHome}/jboss-5.1.0.GA/server/default/conf/connector.properties"
adminPrefs="${pfsHome}/jboss-5.1.0.GA/server/default/admin.prefs"



echo
echo "Backing up the files....."
echo

backupDir="${pfsHome}/jboss-5.1.0.GA/BEFORE_SSO"
runCmd "mkdir -p ${backupDir}"


echo
echo  "Copying original files from BACKUP directory, if exists ....."
echo

### Copy from BACKUP location first
if [ -e "${backupDir}/default.cfg" ]
then
	runCmd "cp ${backupDir}/default.cfg $defaultCfg"	
fi

if [ -e "${backupDir}/login-config.xml" ]
then
	runCmd "cp ${backupDir}/login-config.xml $loginConfig"
fi


if [ -e "${backupDir}/sso.war" ]
then
	runCmd "cp ${backupDir}/sso.war $ssoWar"
fi


if [ -e "${backupDir}/picketlink-sts-1.0.0.war" ]
then
	runCmd "cp ${backupDir}/picketlink-sts-1.0.0.war $picketLinkWar"
fi


if [ -e "${backupDir}/usermanager.properties" ]
then
	runCmd "cp ${backupDir}/usermanager.properties $userManagerFile"	
fi

if [ -e "${backupDir}/connector.properties" ]
then
	runCmd "cp ${backupDir}/connector.properties $connectorPropFile"	
fi


### Let us copy only for the first time - i.e. do not copy if the files already exist

if [ ! -f "${backupDir}/default.cfg" ]
then
	runCmd "cp $defaultCfg ${backupDir}"
else
	echo
	echo "INFO : default.cfg already exists at Backup location. Not copying again."
	echo
fi

if [ ! -f "${backupDir}/login-config.xml" ]
then
	runCmd "cp $loginConfig ${backupDir}"
else
	echo
	echo "INFO : login-config.xml already exists at Backup location. Not copying again."
	echo
fi

if [ ! -f "${backupDir}/sso.war" ]
then
	runCmd "cp $ssoWar ${backupDir}"
else
	echo
	echo "INFO : sso.war already exists at Backup location. Not copying again."
	echo
fi

if [ ! -f "${backupDir}/picketlink-sts-1.0.0.war" ]
then
	runCmd "cp $picketLinkWar ${backupDir}"
else
	echo
	echo "INFO : picketlink-sts-1.0.0.war already exists at Backup location. Not copying again."
	echo
fi

if [ ! -f "${backupDir}/usermanager.properties" ]
then
	runCmd "cp $userManagerFile ${backupDir}"
else
	echo
	echo "INFO : usermanager.properties already exists at Backup location. Not copying again."
	echo
fi

if [ ! -f "${backupDir}/connector.properties" ]
then
	runCmd "cp $connectorPropFile ${backupDir}"
else
	echo
	echo "INFO : connector.properties already exists at Backup location. Not copying again."
	echo
fi



echo
echo "INFO : Files before updating is available @ $backupDir"
echo



### Step 2. Let us copy the login-config.xml


loginConfig_ORG="${scriptDir}/login-config.xml_ORG"
loginConfig_SSO="${scriptDir}/login-config.xml_SSO"

### Disable path here
if [ "${disableSSO}" == "true" ]
then
	loginConfig_SSO="${scriptDir}/login-config.xml_NON_SSO"
fi



if [ ! -f $loginConfig_SSO ]
then
	echo "ERROR : Unable to find SSO login-config file $loginConfig_SSO"
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi

echo
echo "Checking whether there are any changes to login-config.xml in this sprint ....."
echo

compareFile "$loginConfig" "$loginConfig_ORG"

if [ $? -ne 0 ]
then
	echo 	
	echo "INFO : Looks like login-config.xml used for templatization has changed. Let us check if required SSO configurations are already in place....."
	echo
	
	compareFile "$loginConfig" "$loginConfig_SSO"

	if [ $? -ne 0 ]
	then
		echo
		echo "ERROR : login-config.xml used for templatization has changed. Script may not work properly."
		echo
		echo "Backup files are available at $backupDir."
		echo
		exit 1
	else
		echo 
		echo "INFO : login-config.xml already has required SSO configurations, no action required"
		echo
	fi
else
	echo
	echo "INFO : No changes in the login-config.xml in this sprint."
	echo
	runCmd "cp $loginConfig_SSO $loginConfig"
fi


### Exit the script if disable was passed
if [ "${disableSSO}" == "true" ]
then
	echo
	echo "Successfully disabled SSO in the environment."
	echo
#
### END for disable path
#
	date=`date`
	echo
	echo "Script end time : $date"
	echo
	exit 0;
fi

### Step 1. Let us check the default.cfg first

defaultCfg="${pfsHome}/jboss-5.1.0.GA/server/default/conf/default.cfg"

if [ ! -r $defaultCfg ]
then
	echo
	echo "ERROR : Unable to read $defaultCfg"
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi

updatePairValue "$defaultCfg" "sso.enable" "true"



### Step 3. Update sso.war

ssoWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/sso.war"

if [ ! -f $ssoWar ]
then
	echo
	echo "ERROR : Unable to find $ssoWar"
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi

echo
echo

### Let us unzip the war in a temporary directory first
tempDir="/tmp/sso_temp_dir"

runCmd "rm -rf $tempDir"

echo "Let us explode the SSO war file into a temporary directory ....."
runCmd "unzip -qod $tempDir $ssoWar"

### Step 3.1. Update config.properties first

configProp="${tempDir}/WEB-INF/config.properties"

echo "Config properties file : $configProp "

### ldap.ip-address=192.168.4.192

if [ "x${ldapHost}" == "x" ]
then
	echo "Enter the LDAP Hostname [Default : 192.168.4.2] : "
	read ldapHost
fi

if [ "x${ldapHost}" == "x" ]
then
	ldapHost="192.168.4.2"
	echo
	echo "INFO : LDAP hostname is not provied, using the default hostname $ldapHost"
	echo
else
	echo
	echo "INFO : Using the LDAP hostname $ldapHost"
	echo
fi




###ldap.port=636
if [ "x${ldapPort}" == "x" ]
then
	echo "Enter the LDAP port number [Default : 636] : "
	read ldapPort
fi

if [ "x${ldapPort}" == "x" ]
then
	ldapPort="636"
	echo
	echo "INFO : LDAP port number is not provied, using the default port number $ldapPort"
	echo
else
	echo
	echo "INFO : Using the LDAP port number $ldapPort"
	echo
fi


###ldap.usercontatiner=cn=users,dc=dh,dc=com
if [ "x${ldapContainer}" == "x" ]
then
	echo "Enter the LDAP user container [Default : cn=users,dc=dhindia,dc=com] : "
	read ldapContainer
fi

if [ "x${ldapContainer}" == "x" ]
then
	ldapContainer="cn=users,dc=dhindia,dc=com"
	echo
	echo "INFO : LDAP port number is not provied, using the default port number $ldapContainer"
	echo
else
	echo
	echo "INFO : Using the LDAP container $ldapContainer"
	echo
fi


###ldap.domain=dh.com
if [ "x${ldapDomain}" == "x" ]
then
	echo "Enter the LDAP Domain name [Default : dhindia.com] : "
	read ldapDomain
fi

if [ "x${ldapDomain}" == "x" ]
then
	ldapDomain="dhindia.com"
	echo
	echo "INFO : LDAP domain name is not provied, using the default domain name $ldapDomain"
	echo
else
	echo
	echo "INFO : Using the LDAP domain name $ldapDomain"
	echo
fi

###ldap.admin=administrator
if [ "x${ldapUsername}" == "x" ]
then
	echo "Enter the LDAP administrator username [Default : administrator] : "
	read ldapUsername
fi

if [ "x${ldapUsername}" == "x" ]
then
	ldapUsername="administrator"
	echo
	echo "INFO : LDAP administrator username is not provied, using the default adminstrator username $ldapUsername"
	echo
else
	echo
	echo "INFO : Using the administrator username $ldapUsername"
	echo
fi

#ldap.admin.passwd=dharbor@1
if [ "x${ldapPassword}" == "x" ]
then
	echo "Enter the LDAP administrator password [Default : Neomatrix@3] : "
	read ldapPassword
fi

if [ "x${ldapPassword}" == "x" ]
then
	ldapPassword="Neomatrix@3"
	echo
	echo "INFO : LDAP administrator password is not provied, using the default administrator password $ldapPassword"
	echo
else
	echo
	echo "INFO : Using the administrator password $ldapPassword"
	echo
fi

#portal.ip=a.b.c.d
ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`

if [ "x${portalIP}" == "x" ]
then
	echo "Enter the Portal IP [Default - current hostname IP Address $ipAddress] : "
	read portalIP
fi

if [ "x${portalIP}" == "x" ]
then
	portalIP="$ipAddress"
	echo
	echo "INFO : Portal IP address is not provied, using the default of current host IP Address $portalIP"
	echo
else
	echo
	echo "INFO : Using the Portal IP Address $portalIP"
	echo
fi


#portal.port=8080
if [ "x${portalPort}" == "x" ]
then
	echo "Enter the Portal Port [Default : 8080] : "
	read portalPort
fi

if [ "x${portalPort}" == "x" ]
then
	portalPort="8080"
	echo
	echo "INFO : Portal port number is not provied, using the default of $portalPort"
	echo
else
	echo
	echo "INFO : Using the Portal port number $portalPort"
	echo
fi

### Ask whether the env is SSL or non-SSL
if [ "x${isSSL}" == "x" ]
then
	echo "Is the environment SSL or non-SSL [Enter 1 for SSL or 2 for non-SSL. Default : SSL]"
	read isSSL
fi


echo
echo "INFO : Using the current Hostname IP Address for configuring Picketlink SAML URL - $ipAddress"
echo

if [ "x${isSSL}" == "x" ] || [ "${isSSL}" == "1" ] || [ "${isSSL}" == "true" ]
then
	sslPort="8443"
	http="https"
	echo
	echo "INFO : Using the SSL configurations - port : 8443."
	echo
	samlUrl="${http}://${ipAddress}:${sslPort}/picketlink-sts-1.0.0/PicketLinkSTS"
### Reset the flag - we can use it later
	isSSL="true"
else
	sslPort="8080"
	http="http"
	echo
	echo "INFO : Using the non-SSL configurations - port : 8080."
	echo
	samlUrl="${http}://${ipAddress}:${sslPort}/picketlink-sts-1.0.0/PicketLinkSTS"
	isSSL="false"
fi

#serverType=default
if [ "x${serverType}" == "x" ]
then
	echo "Enter the Server Type [Default : default] : "
	read serverType
fi

if [ "x${serverType}" == "x" ]
then
	serverType="default"
	echo
	echo "INFO : Server Type is not provied, using the default of $serverType"
	echo
else
	echo
	echo "INFO : Using the Server Type $serverType"
	echo
fi


#sso.hosted.server.for=portal
if [ "x${hostedServer}" == "x" ]
then
	echo "Enter the Hosted Server (enrollment or portal) [Default : enrollmment] : "
	read hostedServer
fi

if [ "x${hostedServer}" == "x" ]
then
	hostedServer="enrollment"
	echo
	echo "INFO : Hosted Server is not provied, using the default of $hostedServer"
	echo
else
	echo
	echo "INFO : Using the Hosted Server $hostedServer"
	echo
fi


#docviewerURL=http://192.168.4.77:8080/prizmccplusjsp/full-viewer-sample/index.jsp?document=CA_Terms_and_Conditions_PolicyStatement.pdf
docViewerUrl="${http}://${portalIP}:${sslPort}/prizmccplusjsp/full-viewer-sample/index.jsp?document=CA_Terms_and_Conditions_PolicyStatement.pdf"


#enrolment.dburl=jdbc:JSQLConnect://192.168.4.206:1433/databaseName=KYPPORTALDinesh/selectMethod=Cursor/asciiStringParameters=true/ssl=mandatory/sslTrusted=false
### We can get the DB Hostname and DB Name from admin.prefs
#DBServer=192.168.4.145
#DBName=LinuxDB
#DBPort=1433

dbHost=`grep ^DBServer= $adminPrefs | awk -F'=' '{print $2}'`
dbName=`grep ^DBName= $adminPrefs | awk -F'=' '{print $2}'`
dbPort=`grep ^DBPort= $adminPrefs | awk -F'=' '{print $2}'`




dbSslFlag=`grep ^usermanager.jdbc.url $userManagerFile | grep sslTrusted`

if [ "x${dbSslFlag}" == "x" ]
then
	dbUrl="jdbc:JSQLConnect://${dbHost}:${dbPort}/databaseName=${dbName}/selectMethod=Cursor/asciiStringParameters=true"
else
	dbUrl="jdbc:JSQLConnect://${dbHost}:${dbPort}/databaseName=${dbName}/selectMethod=Cursor/asciiStringParameters=true/ssl=mandatory/sslTrusted=false"
fi

#enrolment.dbuser=sa
### We can get the DB username from admin.prefs
#DBUser=sa
dbUsername=`grep ^DBUser= $adminPrefs | awk -F'=' '{print $2}'`


#enrolment.dbpassword=dhi123$
### We can get the DB username password from admin.prefs
#DBPassword=dhi123$
dbUserPass=`grep ^DBPassword= $adminPrefs | awk -F'=' '{print $2}'`


### Now update the config.properties 
updatePairValue "$configProp" "ldap.ip-address" "$ldapHost"
updatePairValue "$configProp" "ldap.port" "$ldapPort"
updatePairValue "$configProp" "ldap.usercontatiner" "$ldapContainer"
updatePairValue "$configProp" "ldap.domain" "$ldapDomain"
updatePairValue "$configProp" "ldap.admin" "$ldapUsername"
updatePairValue "$configProp" "ldap.admin.passwd" "$ldapPassword"


updatePairValue "$configProp" "portal.ip" "$portalIP"
updatePairValue "$configProp" "portal.port" "$portalPort"



#PicketLink related configs^M
#sso.samlurl=http://192.168.4.77:8080/picketlink-sts-1.0.0/PicketLinkSTS^M
updatePairValue "$configProp" "sso.samlurl" "${samlUrl}"

### default.cfg needs to be updated depending on the SSL or non-SSL configuration
#picketlinkSTS.Webservice.endpointURI=http://localhost:8080/picketlink-sts-1.0.0/PicketLinkSTS
updatePairValue "$defaultCfg" "picketlinkSTS.Webservice.endpointURI" "${samlUrl}"


updatePairValue "$configProp" "enrolment.dburl" "$dbUrl"
updatePairValue "$configProp" "enrolment.dbuser" "$dbUsername"
updatePairValue "$configProp" "enrolment.dbpassword" "$dbUserPass"

updatePairValue "$configProp" "docviewerURL" "$docViewerUrl"

updatePairValue "$configProp" "serverType" "$serverType"
updatePairValue "$configProp" "sso.hosted.server.for" "$hostedServer"

### For portal, update the landing url
if [ "$hostedServer" == "portal" ]
then
	updatePairValue "$configProp" "portal.ssolandingurl" "authn/samlAuthentication.do"
fi



### Update the sso.war with the updated config.properties

echo
echo "Updating sso.war with the modified config.properties file....."
echo

currDir=`pwd`

cd $tempDir
runCmd "zip -u $ssoWar WEB-INF/config.properties"
cd $currDir

### Remove the temporary directory
runCmd "rm -rf $tempDir"

## Picketlink war related changes

picketLinkWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/picketlink-sts-1.0.0.war"
if [ ! -f $picketLinkWar ]
then
	echo
	echo "ERROR : Unable to find $picketLinkWar"
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi

### Let us unzip the war in a temporary directory first
tempDir="/tmp/picketlink_temp_dir"

runCmd "rm -rf $tempDir"

echo "Let us explode the PicketLink war file into a temporary directory ....."
runCmd "unzip -qod $tempDir $picketLinkWar"

#
#############
#

wsdlFile="${tempDir}/WEB-INF/wsdl/PicketLinkSTS.wsdl"

wsdlFile_ORG="${scriptDir}/PicketLinkSTS.wsdl_ORG"

compareFile "$wsdlFile" "$wsdlFile_ORG"

if [ $? -ne 0 ]
then
	echo
	echo "ERROR : Looks like there are some changes to PicketLinkSTS.wsdl file in this sprint. The script may not work properly."
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi


### wldl is an XML file, not in pair-value format, we need to deal with it little differently

# Get the current value of PicketLink using the grep command
#grep picketlink-sts-1.0.0 WEB-INF/wsdl/PicketLinkSTS.wsdl
#oldLine='<soap12:address location=\"http://192.168.4.77:8080/picketlink-sts-1.0.0\"/>'

searchText="https://192.168.4.8:8443/picketlink-sts-1.0.0"
searchText="http://192.168.4.77:8080/picketlink-sts-1.0.0"
echo "grep $searchText $wsdlFile"
grep $searchText $wsdlFile

if [ $? -ne 0 ]
then
	echo
	echo "INFO: "

	echo
	echo "ERROR : Unable to find the old line to be replaced. Script requires the below line to be present."
	echo
	echo "Search Text : $searchText"
	echo
	echo "Line : $oldText"
	echo 
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi

picketLinkUrl="${http}://${ipAddress}:${sslPort}/picketlink-sts-1.0.0"

replaceText $wsdlFile "$searchText" "$picketLinkUrl"


### Let us update the WSDL file now
echo
echo "Updating picketlink-sts-1.0.0.war with the modified PicketLinkSTS.wsdl file....."
echo

cd $tempDir
runCmd "zip -u $picketLinkWar WEB-INF/wsdl/PicketLinkSTS.wsdl"
cd $currDir


if [ "$isSSL" == "true" ]
then

### Update the identity.jks file only when SSL is enabled

echo
echo "Updating the identity.jks to $picketLinkWar"
echo

runCmd "cp ${pfsHome}/jboss-5.1.0.GA/server/default/conf/identity.jks ${tempDir}/WEB-INF/classes"

cd $tempDir
runCmd "zip -u $picketLinkWar WEB-INF/classes/identity.jks"
cd $currDir


### Copy the correct web.xml and update picketlink WAR file

	webXml="${scriptDir}/web.xml_SSL"
	picketLinkStsXml="${scriptDir}/picketlink-sts.xml_SSL"
else
	webXml="${scriptDir}/web.xml_NON_SSL"
	picketLinkStsXml="${scriptDir}/picketlink-sts.xml_NON_SSL"
fi

echo
echo "Copying the web.xml to WEB-INF directory"
echo

runCmd "cp $webXml ${tempDir}/WEB-INF/web.xml"

echo
echo "Updating the web.xml to $picketLinkWar"
echo

cd $tempDir
runCmd "zip -u $picketLinkWar WEB-INF/web.xml"
cd $currDir


echo
echo "Copying the picketlink-sts.xml to WEB-INF/classes directory"
echo

runCmd "cp $picketLinkStsXml ${tempDir}/WEB-INF/classes/picketlink-sts.xml"

echo
echo "Updating the picketlink-sts.xml to $picketLinkWar"
echo

cd $tempDir
runCmd "zip -u $picketLinkWar WEB-INF/classes/picketlink-sts.xml"
cd $currDir

### Remove the contents of tempDir at the end
runCmd "rm -rf $tempDir"


#
### usermanager.properties
#
echo
echo "Creating usermanager.properties ....."
echo


### DB Username Encrypted password can be obtained from usernamager.properties

dbUserPassEnc=`grep ^usermanager.jdbc.password= $userManagerFile | awk -F'=' '{print $2}'`
ldapSslFlag=`grep ^usermanager.ldap.ssl_is_enabled= $userManagerFile | awk -F'=' '{print $2}'`


if [ "x${dbSslFlag}" == "x" ]
then
### DB is non-SSL
	dbJdbcSslParams="";	
else
### DB is SSL
	dbJdbcSslParams="/ssl\\=mandatory/sslTrusted\\=false";	
fi


userManagerFileUpdated="/tmp/usermanager.properties"

runCmd "rm -f $userManagerFileUpdated"

if [ "$ldapPassword" == "Neomatrix@4" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="T3NHRmZFc2FuQ3I5dEtMRkVJSXpJQT09"
fi

if [ "$ldapPassword" == "Neomatrix@1" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="UmJoYmUzZnZQY1RSV1hMcGxwUUlxZz09"
fi

if [ "$ldapPassword" == "Neomatrix@2" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="c0RaOEFvbWJnN2VHcnora0w3VTBBZz09"
fi

if [ "$ldapPassword" == "Neomatrix@3" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="Wkxlcm80NU1OdzZyNklTU2dSZDkxZz09"
fi

if [ "$ldapPassword" == "DHarbor@1" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="TDk1Tm5TSFNKZ0dmTVkyVUtNVE5rQT09"
fi

if [ "$ldapPassword" == "dharbor@1" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="Y1lnVUFMUlIzem9iYXZTamxGTyt4UT09"
fi

### AWS SIT LDAP
if [ "$ldapPassword" == "ot5fJz%h&rH" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
	ldapPasswordEnc="TG9SNjRneTMyUUI2cC9YOCtheXVlQT09"
fi

### AWS QA LDAP
if [ "$ldapPassword" == ")EBg6P&oLV9" ] && [ "x${ldapPasswordEnc}" == "xx" ]
then
        ldapPasswordEnc="VldUbHVjK2hpQi9weTQzRjcyVzJ2UT09"
fi



if [ "x${ldapPasswordEnc}" == "xx" ]
then
	echo
	echo "ERROR : Unable to determine the encrypted value for the LDAP password ${ldapPassword}, please perform the steps manually"
	echo
	echo "Backup files are available at $backupDir."
	echo
	exit 1
fi


ldapCnWithSlash=`echo $ldapContainer | sed 's+=+\\\=+g'`

echo "
usermanager.jdbc.username=$dbUsername
usermanager.ldap.groups.root=$ldapCnWithSlash
usermanager.ldap.arl_attribute_name=
usermanager.ldap.piieadmin.mapped_groups=
usermanager.ldap.user.root=$ldapCnWithSlash
usermanager.ldap.binding_user=$ldapUsername
usermanager.jdbc.conn.pool.maxsize=5
usermanager.ldap.ssl_is_enabled=true
usermanager.jdbc.conn.pool.incrementsize=1
usermanager.ldap.crl_attribute_name=
usermanager.ldap.crl_dn_list=
usermanager.jdbc.password=$dbUserPassEnc
usermanager.ldap.port=$ldapPort
usermanager.ldap.anonymous=false
usermanager.jdbc.driver=com.jnetdirect.jsql.JSQLDriver
usermanager.ldap.active_directory_domain_name=$ldapDomain
usermanager.ldap.is_active_directory=true
usermanager.ldap.host=${ldapHost}|
usermanager.ldap.piieoperator_everyone.mapped_groups=
usermanager.ldap.connection_timeout_milliseconds=20000
usermanager.jdbc.url=jdbc\:JSQLConnect\://${dbHost}\:1433/databaseName\=${dbName}/selectMethod\=cursor${dbJdbcSslParams}
usermanager.ldap.dir_context_factory_class=com.digitalharbor.security.connector.ldap.dircontextfactories.AnonymousDirContextFactory
usermanager.ldap.context_factory=com.sun.jndi.ldap.LdapCtxFactory
usermanager.database.server=${dbHost}
usermanager.ldap.db_pwd_alias=
usermanager.database.name=$dbName
usermanager.ldap.binding_password=$ldapPasswordEnc
" > $userManagerFileUpdated


#### Changes required for making it work after model deployment as usermanager.propertries gets changes

runCmd "cp $userManagerFile $userManagerFileUpdated"

updatePairValue "$userManagerFileUpdated" "usermanager.ldap.groups.root" "$ldapCnWithSlash"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.arl_attribute_name" ""
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.user.root" "$ldapCnWithSlash"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.binding_user" "$ldapUsername"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.ssl_is_enabled" "true"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.crl_attribute_name" ""
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.port" "$ldapPort"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.anonymous" "false"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.active_directory_domain_name" "$ldapDomain"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.is_active_directory" "true"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.host" "${ldapHost}|"
updatePairValue "$userManagerFileUpdated" "usermanager.ldap.binding_password" "$ldapPasswordEnc"

echo "usermanager.ldap.piieoperator_everyone.mapped_groups=" >> $userManagerFileUpdated
echo "usermanager.ldap.anonymous=false" >> $userManagerFileUpdated



echo
echo "Checking whether there are any changes to usermanager.properties in this sprint ....."
echo

userManagerFile_ORG="/tmp/usermanager.properties_ORG"
runCmd "cp ${scriptDir}/usermanager.properties_ORG $userManagerFile_ORG"


### Update the usermanager.properties_ORG file before comparing

#usermanager.jdbc.url=jdbc\:JSQLConnect\://${dbHost}\:1433/databaseName\=${dbName}/selectMethod\=cursor/ssl\=mandatory/sslTrusted\=false
#usermanager.database.name=$dbName

if [ "x${dbSslFlag}" == "x" ]
then
	updatePairValue "$userManagerFile_ORG" "usermanager.jdbc.url" "jdbc\\:JSQLConnect\\://${dbHost}\\:${dbPort}/databaseName\\=${dbName}/selectMethod\\=cursor"
else
	updatePairValue "$userManagerFile_ORG" "usermanager.jdbc.url" "jdbc\\:JSQLConnect\\://${dbHost}\\:${dbPort}/databaseName\\=${dbName}/selectMethod\\=cursor/ssl\\=mandatory/sslTrusted\\=false"
fi


updatePairValue "$userManagerFile_ORG" "usermanager.database.name" "$dbName"
updatePairValue "$userManagerFile_ORG" "usermanager.jdbc.password" "$dbUserPassEnc"
updatePairValue "$userManagerFile_ORG" "usermanager.jdbc.username" "$dbUsername"
updatePairValue "$userManagerFile_ORG" "usermanager.database.server" "$dbHost"
updatePairValue "$userManagerFile_ORG" "usermanager.ldap.ssl_is_enabled" "$ldapSslFlag"



### We need to remove the comments from the usermanager.properties as it contains the date stamp
tempFile="/tmp/tempUserManagerFile"


echo
echo "INFO: Verifying whether there are any recent changes to usermanager.properties file ....."
echo


echo
echo "Removing comments from usermanager.properties file - it contains date stamp"
echo

echo "Running the command : "
echo "grep -v ^# $userManagerFile > $tempFile"
echo
grep -v ^# $userManagerFile > $tempFile

### Commenting out temporarily to allow changes after model deployment
#compareFile "$tempFile" "$userManagerFile_ORG"


if [ $? -ne 0 ]
then
	echo 	
	echo "INFO : Looks like usermanager.properties used for templatization has changed. Let us check if required LDAP configurations are already in place....."
	echo
	
	compareFile "$userManagerFile" "$userManagerFileUpdated"
	
	if [ $? -ne 0 ]
	then
		echo
		echo "ERROR : usermanager.properties file used templatization has changed. The script may not function propertly"
		echo
		echo "Backup files are available at $backupDir."
		echo
		exit 1
	else
		echo
		echo "INFO : usermanager.properties file already contains the required changes. No action required."
		echo
	fi
else
	
### Let us copy usermanager.properties to conf folder
	echo
	echo "Copying usermanager.properties file to conf folder ....."
	echo
	runCmd "cp $userManagerFileUpdated ${pfsHome}/jboss-5.1.0.GA/server/default/conf"
fi




runCmd "rm -f $userManagerFileUpdated"
runCmd "rm -f $tempFile"
runCmd "rm -f $userManagerFile_ORG"


### connector.properties file needs to be updated 
#Connector.UserManager.CHAIN=base jdbc
#Connector.UserManager.CHAIN=base ldap

updatePairValue "$connectorPropFile" "Connector.UserManager.CHAIN" "base ldap"



echo
echo "Done making SSO configuration changes"
echo


#
### END
#
date=`date`
echo
echo "Script end time : $date"
echo



### Now exit gracefully
exit 0

