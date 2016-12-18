#!/bin/bash


#
### Usage function
#
usage()
{

        echo "
Usage :
./ssl.sh [-help] [-pfsHome=<pfs install location>] [-silent] [-releaseLocation=<Release bits Location>]  [-disable] [-propFile=<properties file>]

Where:
pfsHome         : PFS Install location [Default : $HOME/PFS/TEST]
releaseLocation : Release location [Default : NONE]
useWildCard     : Domain name for generating domain specific SSL certificate [Default : NONE]
sslExt          : DNS names and IP addresses to be used as extensions for wildcard SSL key [Default : Current host IP address]
disable         : Disable SSL [Default : FALSE]
silent          : Do not prompt for inputs, use default values
propFile        : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.

Eg:
./ssl.sh -pfsHome=/path/to/PFS/HOME

./ssl.sh -propFile=/path/to/env.properties

./ssl.sh -pfsHome=/home/db/PFS/TEST -disable

./ssl.sh -useWildCard=*.digitalharbor.us -sslExt=dns:node1.digitalharbor.us,ip:192.168.4.8


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
        -disable)
            disableSSL="true"
            ;;
        -propFile)
            propFile=$VALUE
            ;;
        -useWildCard)
            useWildCard=$VALUE
            ;;
        -sslExt)
            sslExt=$VALUE
            ;;
        -releaseLocation)
            releaseLocation=$VALUE
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        *)
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
echo " 		SSL Configuration script"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
#
### BEGIN
#
date=`date`
echo 
echo "Script start time : $date"
echo



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

        if [ "x${pfsHost}" == "x" ]
        then
		hostname=`hostname`
                getKeyValue "${propFile}" "pfs.home" "$hostname"
                pfsHost=$value
        fi


        if [ "x${pfsHome}" == "x" ]
        then
                getKeyValue "${propFile}" "pfs.home"
                pfsHome=$value
        fi

        if [ "x${useWildCard}" == "x" ]
        then
                getKeyValue "${propFile}" "pfs.ssl.wildcard" "$hostname"
                useWildCard=$value
        fi

        if [ "x${sslExt}" == "x" ]
        then
### Get the IP Address of the machine, this is needed to generate the machine specific certificate
                ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
                getKeyValue "${propFile}" "pfs.ssl.san.ext" "ip:${ipAddress}"
                sslExt=$value
        fi




### Enable silent mode as properties file is passed
	silent="true"

fi



### Let us try to prompt the user for PFS_HOME, OMS DB and OMS DB Hostname in case not provided as a parameter

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

echo

if [ ! -r $pfsHome ]
then
	echo
	echo "ERROR : Unable to read $pfsHome directory"
	echo
	exit 1
fi

### SSL Configurations start here

### Generate identity.jks file
echo
echo "Starting SSL Configurations ....."
echo "---------------------------------"
echo

echo
echo "Updating server.xml under deploy/jbossweb.sar....."
echo

serverXml="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/jbossweb.sar/server.xml"

serverXml_ORG="${scriptDir}/server.xml_ORG"
serverXml_SSL="${scriptDir}/server.xml_SSL"
if [ "${disableSSL}" == "true" ]
then
	serverXml_SSL="${scriptDir}/server.xml_NON_SSL"
	echo
	echo "INFO : Disabling SSL in server.xml ....."
	echo 
fi
serverXml_NON_SSL="server.xml_NON_SSL"


backupDir="${pfsHome}/jboss-5.1.0.GA/BEFORE_SSL"
runCmd "mkdir -p ${backupDir}"

### If there is anything in BEFORE_SSL folder, let us copy it back to the original location

if [ -e ${backupDir}/server.xml ]
then
	echo
	echo "INFO : Copying back the original server.xml from BACKUP directory ....."
	echo
	runCmd "cp ${backupDir}/server.xml $serverXml"
fi




echo
echo "Checking whether there are any changes to server.xml in this sprint ....."
echo

compareFile "$serverXml" "$serverXml_ORG"

if [ $? -ne 0 ]
then
	echo 	
	echo "INFO : Looks like server.xml used for templatization has changed. Let us check if required SSL configurations are already in place....."
	echo
	
	compareFile "$serverXml" "$serverXml_SSL"

	if [ $? -ne 0 ]
	then
		echo
		echo "ERROR : server.xml used for templatization has changed. Script may not work properly."
		echo
		exit 1
	else
		echo 
		echo "INFO : server.xml already has required SSL configurations, no action required"
		echo
	fi
else
	echo "Backing up the existing server.xml ....."
	runCmd "cp $serverXml $backupDir"

### Let us copy the SSL configuration file now
	echo 
	echo "Copying server.xml with SSL changes"
	echo

	runCmd "cp $serverXml_SSL $serverXml"
fi


if [ "${disableSSL}" == "true" ]
then
	echo	
	echo "Done disabling SSL in the environment."
	echo
#
### END
#
	date=`date`
	echo
	echo "Script end time : $date"
	echo
	exit 0;

fi
###################################################################################################


JAVA_HOME="${pfsHome}/jdk1.6.0_17"

### Check the JAVA_HOME

if [ ! -x "${JAVA_HOME}/bin/java" ]
then
	echo
	echo "ERROR : Java executable is NOT FOUND at ${JAVA_HOME}/bin/java"
	echo
	exit 1
fi

runCmd "${JAVA_HOME}/bin/java -version"

echo
echo "Using the JAVA_HOME : $JAVA_HOME"
echo


echo
echo "Keytool option -ext requires JDK1.8 to be used. Let us unzip it first from MISC directory."
echo

if [ "x${releaseLocation}" == "x" ]
then
	echo
	echo "Enter the Release location : "
	echo
	read releaseLocation
fi

jdk18Top="$HOME"
jdk18Zip="${releaseLocation}/MISC/jdk-8u72-linux-x64.tar.gz"
jdk18Home="${jdk18Top}/jdk1.8.0_72"


if [ ! -r $jdk18Zip ]
then
        echo
        echo "ERROR : Unable to read $jdk18Zip";
        echo
        exit 1
fi



backupFile $jdk18Home

runCmd "tar -zxf $jdk18Zip -C $jdk18Top"

echo
export PATH=$jdk18Home/bin:$PATH
echo "Using PATH : $PATH"
echo



### Get the IP Address of the machine, this is needed to generate the machine specific certificate

echo
cmd="ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'"
echo "Getting the IP address of the machine using the command :"
echo "$cmd"
echo
ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
echo "IP Address : $ipAddress"

hostname=`hostname`

identityJksFile="${pfsHome}/identity.jks"
clientCerFile="${pfsHome}/client.cer"


echo
echo "Generating identity.jks file ....."
echo

backupFile $identityJksFile
if [ "X${useWildCard}" = "X" ]
then
        hostname=`hostname`
else
        hostname="$useWildCard"

fi

if [ "X${sslExt}" = "X" ]
then
        sslSanExt="ip:${ipAddress}"
else
        sslSanExt="$sslExt"

fi



which keytool

cmd="${jdk18Home}/bin/keytool -v -genkey -keyalg RSA -sigalg SHA256withRSA -keystore $identityJksFile -keysize 2048 -alias piekey -keypass password -storepass password -validity 3650 -dname \"CN=${hostname}, OU=PiiE Engine, O=Digital Harbor, L=Provo, S=UT, C=US\" -ext san=${sslSanExt}"

echo
echo "Running the command - 1 : $cmd"

rm -f /tmp/${datestamp}.sh

echo $cmd > /tmp/${datestamp}.sh
chmod 755 /tmp/${datestamp}.sh
/tmp/${datestamp}.sh
RC=$?
echo "Done."
rm -f /tmp/${datestamp}.sh

echo 
echo "Copying $identityJksFile to ${pfsHome}/jboss-5.1.0.GA/server/default/conf"
runCmd "cp $identityJksFile ${pfsHome}/jboss-5.1.0.GA/server/default/conf"
echo

echo
echo "Export piekey to a certificate."
echo


runCmd "${jdk18Home}/bin/keytool -v -export -alias piekey -file ${clientCerFile} -keystore ${identityJksFile} -storepass password"

rm -f /tmp/${datestamp}.sh

#
### Remove the entry before attempting to import
#

echo
echo "Checking if piekey alias already exists in the keystore ${JAVA_HOME}/jre/lib/security/cacerts....."
echo

cmd="${jdk18Home}/bin/keytool -noprompt -list -alias piekey -keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit"

echo
echo "Running the command :"
echo $cmd
echo

$cmd

if [ $? -eq 0 ]
then
	echo
	echo "piekey alias already exists in the keystore ${JAVA_HOME}/jre/lib/security/cacerts. Let us remove it first."
	echo

	cmd="${jdk18Home}/bin/keytool -v -noprompt -delete -alias piekey -keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit"
	echo
	echo "Removing the alias entry in ${JAVA_HOME}/jre/lib/security/cacerts for piekey"
	echo
	runCmd "$cmd"
else
	echo
	echo "piekey alias does not exist currently in the keystore ${JAVA_HOME}/jre/lib/security/cacerts."
	echo
fi

echo
echo "Import the client_PFS.cer to JDK 1.6 used by PFS"
echo

#
### Import client.cer into cacerts
#
cmd="${jdk18Home}/bin/keytool -v -noprompt -import -trustcacerts -alias piekey -file ${clientCerFile} -keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit"

runCmd "$cmd"


echo "Note:"
echo "====="
echo "	Copy the $clientCerFile to the DMS machine and import into <JAVA_HOME>/jre/lib/security/cacerts"
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
