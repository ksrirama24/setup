#!/bin/bash

#
### Usage Function
#
usage()
{
        echo "
Usage :
./install_configure_spagobi.sh [-help] [-spagoZip=<SpagoBI Zip location>] [-pfsServer=<PFS Server hostname or IP address>] [-silent] [-pfsPort=<PFS server Port>] [-spagoInstallLoc=<SpagoBI Install location>] [-useWildCard=<domain name for generating domain wildcard SSL certificate>] [-sslExt=<List of DNS/IP extensions for SSL key>]

Where:
spagoZip : SpagoBI zip location (Default : NONE)
pfsServer : PFS server hostname (Default : NONE)
pfsPort : PFS server Port number (Default : 8080)
spagoInstallLoc : SpagoBI Installation location (Default : \$HOME/SpagoBI)
useWildCard : Domain name for generating domain specific SSL certificate (Default : NONE)
sslExt : DNS names and IP addresses to be used as extensions for wildcard SSL key (Default : Current host IP address)
silent : Do not prompt for inputs, use default values


Eg:
./install_configure_spagobi.sh -spagoZip=/path/to/spago/zip/spagoBI.zip

./install_configure_spagobi.sh -useWildCard=*.digitalharbor.us -sslExt=dns:node1.digitalharbor.us,ip:10.0.12.185


Note:
The script needs to be run in bash shell

"

} # End of function usage



echo
echo "SpagoBI Installation Script."
echo


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=${1#${PARAM}=}
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -spagoZip)
            spagoZip=$VALUE
            ;;
        -pfsServer)
            pfsServer=$VALUE
            ;;
        -pfsPort)
            pfsPort=$VALUE
            ;;
        -useWildCard)
            useWildCard=$VALUE
            ;;
        -sslExt)
            sslExt=$VALUE
            ;;
        -spagoInstallLoc)
            spagoInstallLoc=$VALUE
            ;;
        -silent)
            silent="true"
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

####################################################################################

### Setup PATH 
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo
echo "Using PATH : $PATH"
echo




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

####################################################################################


if [ "x${silent}" = "x" ]
then
        silent="false"
else
	echo
	echo "INFO: Script is invoked in silent mode."
	echo

fi

if [ "x${spagoZip}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter Spago ZIP file [Default : NONE]: "
	read spagoZip
fi

if [ "x${pfsServer}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter the PFS server hostname or IP address [Enter Load Balancer name if PFS server is front-ended by LoadBalancer. Default : NONE]: "
	read pfsServer
fi


if [ "x${pfsPort}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter PFS server Port number [Default : 8080]: "
	read pfsPort
fi


if [ "x${spagoInstallLoc}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter SpagoBI server Installation location [Default : $HOME/SpagoBI]:"
	read spagoInstallLoc
fi


if [ "x${pfsPort}" == "x" ]
then
	pfsPort="8080"
	echo
	echo "INFO : PFS  server port number is not provided. Using the port number - $pfsPort"
	echo
else
	echo
	echo "INFO : Using the PFS server port number - $pfsPort"
	echo
fi


if [ "x${spagoInstallLoc}" == "x" ]
then
	spagoInstallLoc="${HOME}/SpagoBI"
	echo
	echo "INFO : SpagoBI installation location is not provided. Using the default location - $spagoInstallLoc"
	echo
else
	echo
	echo "INFO : Using SpagoBI installation location - $spagoInstallLoc"
	echo
fi



if [ "x${spagoZip}" == "x" ]
then
	echo
	echo "ERROR:  Spago Zip is a mandatory parameter. Script can not run without SpagoBI zip supplied."
	echo
	exit 1
fi

if [ "x${pfsServer}" == "x" ]
then
	echo
	echo "ERROR: PFS Server is a mandatory parameter. Script can not run without PFS server hostname supplied."
	echo
	exit 1
fi



if [ ! -r $spagoZip ]
then
	echo
	echo "ERROR: Unable to read SpagoBI zip $spagoZip"
	echo
	exit 1
fi


echo
echo "Backing up SpagoBI installation location if already exists....."
echo

backupFile "${spagoInstallLoc}"
runCmd "mkdir -p ${spagoInstallLoc}"


### Unzip the Spago ZIP

echo
echo "Let us unzip the SpagoBI zip file now ....."
echo

runCmd "unzip -qod $spagoInstallLoc $spagoZip"

### Remove the log files, log directory is requird - should not be removed 

spagoHome="${spagoInstallLoc}/SpagoBI-Server-5.0-16092014"

echo
echo "Removing the old log files ....."
echo

runCmd "rm -rf ${spagoHome}/logs/*"

spagoUsersPropFile="${spagoHome}/conf/spago_users.properties"


### Update spago_users.properties
#fusion.host=192.168.4.185
#fusion.port=8080

if [ ! -r $spagoUsersPropFile ]
then
	echo
	echo "ERROR: SpagoBI Users properties file is NOT found - $spagoUsersPropFile"
	echo
	exit 1
fi

updatePairValue "$spagoUsersPropFile" "fusion.host" "$pfsServer"
updatePairValue "$spagoUsersPropFile" "fusion.port" "$pfsPort"


### SSL Configurations start here

### Generate identity.jks file
echo
echo "Starting SSL Configurations ....."
echo "---------------------------------"
echo

echo
echo "Updating server.xml under conf directory ....."
echo

serverXml="${spagoHome}/conf/server.xml"

serverXml_ORG="${scriptDir}/files/spago_server.xml"
serverXml_tmpl="${scriptDir}/files/spago_server_tmpl.xml"

serverXmlNew="/tmp/server.xml_$$"

echo
echo "Checking whether there are any changes to server.xml in this sprint ....."
echo

if [ ! -r $serverXml ]
then
	echo
	echo "ERROR: Unable to read server.xml at $serverXml"
	echo
	exit 1
fi

if [ ! -r $serverXml_ORG ]
then
	echo
	echo "ERROR: Unable to read server.xml at $serverXml_ORG"
	echo
	exit 1
fi


if [ ! -r $serverXml_tmpl ]
then
	echo
	echo "ERROR: Unable to read server.xml Template at $serverXml_tmpl"
	echo
	exit 1
fi


compareFile "$serverXml" "$serverXml_ORG"

if [ $? -ne 0 ]
then
	echo 	
	echo "ERROR : server.xml used for templatization has changed. Script may not work properly."
	echo
	exit 1;
fi


### identity.jks 
identityJksFile="${spagoHome}/conf/identity.jks"

echo
echo "Using PATH : $PATH"
echo


### keytool is expected to be in the PATH
which keytool

if [ $? -ne 0 ]
then
	echo
	echo "ERROR: keytool is NOT FOUND in PATH. Please add keytool location to PATH."
	echo
	exit 1;
fi



### Get the IP Address of the machine, this is needed to generate the machine specific certificate

echo
cmd="ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'"
echo "Getting the IP address of the machine using the command :"
echo "$cmd"
echo
ipAddress=`ifconfig | grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
echo "IP Address : $ipAddress"


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

### Generate the identity.jks file

backupFile "$identityJksFile"
cmd="keytool -v -genkey -keyalg RSA -sigalg SHA256withRSA -keystore $identityJksFile -keysize 2048 -alias spagokey -keypass password -storepass password -validity 3650 -dname \"CN=${hostname}, OU=PiiE Engine, O=Digital Harbor, L=Provo, S=UT, C=US\" -ext san=${sslSanExt}"


echo
echo "Running the command - 1 : $cmd"

rm -f /tmp/${datestamp}.sh

echo $cmd > /tmp/${datestamp}.sh
chmod 755 /tmp/${datestamp}.sh
/tmp/${datestamp}.sh
RC=$?
echo "Done."
rm -f /tmp/${datestamp}.sh


### Let us update the template file now
# keystoreFile="%identity_jks_path%" keystorePass="password"

runCmd "cp $serverXml_tmpl $serverXmlNew"

replaceText $serverXmlNew "%identity_jks_path%" $identityJksFile



### Let us copy the template file to tmp location
runCmd "cp $serverXmlNew $serverXml"


