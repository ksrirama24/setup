#!/bin/bash

#
### Usage Function
#
usage()
{
        echo "
Usage :
./configure_document_viewer.sh [-help] [-pfsHome=<PFS_HOME location>] [-prizmServer=<Prizm server hostname>] [-silent] [-prizmPort=<Prizm server Port>] [-prizmInstallLoc=<Prizm Server Install location>] [-propFile=<properties file>]

Where:
pfsHome         : PFS_HOME location (Default : NONE)
prizmServer     : Prizm server hostname (Default : 192.168.4.194)
prizmPort       : Prizm server Port number (Default : 18681)
prizmInstallLoc : Prizm Server Installation location (Default : /usr/share/prizm)
isSSL           : true or false (Default : false)
propFile        : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.
silent          : Do not prompt for inputs, use default values


Eg:
./configure_document_viewer.sh -pfsHome=/home/dh/PFS/79212

./configure_document_viewer.sh -propFile=/path/to/file/env.properties

./configure_document_viewer.sh -clientCert=/home/dh/certificate.der 

./configure_document_viewer.sh -clientCert=/home/dh/client_PFS.cer -aliasName=piekey

./configure_document_viewer.sh -clientCert=/home/dh/client_DMS.cer

./configure_document_viewer.sh -clientCert=/home/dh/certificate.der -javaHome=/home/dh/PFS/TEST/jdk1.6.0_17

Note:
The script needs to be run in bash shell

"

} # End of function usage



echo
echo "Creating Document Viewer configuration file....."
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
        -propFile)
            propFile=$VALUE
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        -isSSL)
            isSSL=$VALUE
            ;;
        -noprmopt)
            noprmopt="true"
            ;;
        -prizmServer)
            prizmServer=$VALUE
            ;;
        -prizmPort)
            prizmPort=$VALUE
            ;;
        -prizmInstallLoc)
            prizmInstallLoc=$VALUE
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

### If properties file is provided, get the values from there

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


        if [ "x${prizmServer}" == "x" ]
        then
                getKeyValue "${propFile}" "prizm.hostname"
                prizmServer=$value
        fi

        if [ "x${prizmPort}" == "x" ]
        then
                getKeyValue "${propFile}" "prizm.port"
                prizmPort=$value
        fi

        if [ "x${prizmInstallLoc}" == "x" ]
        then
                getKeyValue "${propFile}" "prizm.install.location"
                prizmInstallLoc=$value
        fi


        if [ "x${isSSL}" == "x" ]
        then
                getKeyValue "${propFile}" "prizm.ssl"
                isSSL=$value
        fi

### Enable silent as properties file is passed
	silent="true"


fi



if [ "x${silent}" = "x" ]
then
        silent="false"
fi

if [ "x${prizmServer}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter Prizm server Hostname [Default : 192.168.4.194]: "
	read prizmServer
fi

if [ "x${isSSL}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Is Prizm server running in SSL [true/false Default : false]: "
	read isSSL
fi


if [ "x${prizmPort}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter Prizm server Port number[Default : 18681]: "
	read prizmPort
fi


if [ "x${prizmInstallLoc}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter Prizm server Installation location [Default : /usr/share/prizm]:"
	read prizmInstallLoc
fi


if [ "x${pfsHome}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo "Enter PFS_HOME location [Default : NONE]:"
	read pfsHome
fi


if [ "x${prizmServer}" == "x" ]
then
	prizmServer="192.168.4.194"
	echo
	echo "INFO : Prizm server hostname is not provided. Using the default hostname - $prizmServer"
	echo
else
	echo
	echo "INFO : Using the Prizm server hostname - $prizmServer"
	echo
fi

if [ "x${prizmInstallLoc}" == "x" ]
then
	prizmInstallLoc="/usr/share/prizm"
	echo
	echo "INFO : Prizm server installation location is not provided. Using the default location - $prizmInstallLoc"
	echo
else
	echo
	echo "INFO : Using the Prizm server installation location - $prizmInstallLoc"
	echo
fi

if [ "x${prizmPort}" == "x" ]
then
	prizmPort="18681"
	echo
	echo "INFO : Prizm server port number is not provided. Using the port number - $prizmPort"
	echo
else
	echo
	echo "INFO : Using the Prizm server port number - $prizmPort"
	echo
fi


### Default is http
if [ "x${isSSL}" == "x" ]
then
	isSSL="false"
fi

if [ "$isSSL" == "true" ]
then
	http="https"
else
	http="http"

fi
	echo
	echo "INFO : Using protocal - $http"
	echo



if [ "x${prizmInstallLoc}" == "x" ]
then
	prizmInstallLoc="192.168.4.22"
	echo
	echo "INFO : Prizm server installation location is not provided. Using the default installation location - $prizmInstallLoc"
	echo
else
	echo
	echo "INFO : Using the Prizm server installation location - $prizmInstallLoc"
	echo
fi

if [ "x${pfsHome}" == "x" ]
then
	echo
	echo "ERROR: PFS_HOME is a mandatory parameter. Script can not run without PFS_HOME supplied."
	echo
	exit 1
fi



configFileTmp="/tmp/documentviewer.cfg"
configFile="${pfsHome}/jboss-5.1.0.GA/server/default/conf/documentviewer.cfg"
prizmWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/prizmccplusjsp.war"

if [ ! -r $prizmWar ]
then
	echo
	echo "ERROR: Unable to read Prizm war file at $prizmWar"
	echo
	exit 1
fi

echo
echo "Backing up the files....."
echo

backupDir="${pfsHome}/jboss-5.1.0.GA/BEFORE_PRIZM_CONFIG"
runCmd "mkdir -p ${backupDir}"


echo
echo  "Copying original files from BACKUP directory, if exists ....."
echo

### Copy from BACKUP location first
if [ -e "${backupDir}/prizmccplusjsp.war" ]
then
	runCmd "cp ${backupDir}/prizmccplusjsp.war $prizmWar"	
fi

### Let us copy only for the first time - i.e. do not copy if the files already exist

if [ ! -f "${backupDir}/prizmccplusjsp.war" ]
then
	runCmd "cp $prizmWar ${backupDir}"
else
	echo
	echo "INFO : prizmccplusjsp.war already exists at Backup location. Not copying again."
	echo
fi


runCmd "rm -f $configFileTmp"

echo
echo "Creating documentviewer.cfg under /tmp"
echo


echo "
documentviewer.location=${prizmInstallLoc}
documentviewer.installed=1
#Prizm Service Proxy REST API web service hostname, If documentviewer is not installed with fusion, default value will be localhost
documentviewer.webservice.host=${prizmServer}
#Prizm Service Proxy REST API web service port number, if port has been changed in prizmccplusjsp.war/web.xml
documentviewer.webservice.port=${prizmPort}
" > $configFileTmp

echo
echo "Copying the documentviewer.cfg to $configFile"
echo
runCmd "cp $configFileTmp $configFile"

#
### Let us update web.xml inside prizmccplusjsp.war now 
#
tempDir="/tmp/prizm"

runCmd "rm -rf $tempDir"

### Let us explode the prizm war in temp directory

runCmd "unzip -qod $tempDir $prizmWar"

webXml="${tempDir}/WEB-INF/web.xml"
webXmlBak="${scriptDir}/files/prizm_web.xml"
webXmlTmpl="${scriptDir}/files/prizm_web_tmpl.xml"

if [ ! -r $webXml ]
then
	echo
	echo "ERROR: Unable to read web.xml at $webXml"
	echo
	exit 1
fi


if [ ! -r $webXmlTmpl ]
then
	echo
	echo "ERROR: Unable to read web.xml Template at $webXmlTmpl"
	echo
	exit 1
fi

compareFile "$webXml" "$webXmlBak"

if [ $? -ne 0 ]
then
	echo 	
	echo "INFO : Looks like web.xml used for templatization has changed. The script may not work properly."
	echo
	exit 1
fi

### Let us copy the template file to tmp location
runCmd "cp $webXmlTmpl $webXml"


### Let us update the web.xml now
#        <param-value>%prizm_documents_path%</param-value>
#        <param-value>%prizm_markup_path%</param-value>
#        <param-value>%prizm_imagetamp_path%</param-value>
#        <param-value>%prizm_http%</param-value>
#        <param-value>%prizm_hostname%</param-value>
#        <param-value>%prizm_port%</param-value>
#

prizmDocPath="${pfsHome}/prizm/Documents"
prizmMarkupPath="${pfsHome}/prizm/Markup"
prizmImagePath="${pfsHome}/prizm/ImageStamp"


runCmd "mkdir -p $prizmDocPath"
runCmd "mkdir -p $prizmMarkupPath"
runCmd "mkdir -p $prizmImagePath"

replaceText $webXml "%prizm_documents_path%" $prizmDocPath
replaceText $webXml "%prizm_markup_path%" $prizmMarkupPath
replaceText $webXml "%prizm_imagetamp_path%" $prizmImagePath
replaceText $webXml "%prizm_http%" $http
replaceText $webXml "%prizm_hostname%" $prizmServer
replaceText $webXml "%prizm_port%"  $prizmPort



### Let us update the war file now
currDir=`pwd`

cd $tempDir
runCmd "zip -u $prizmWar WEB-INF/web.xml"
cd $currDir


### Let us delete the tempDir now
runCmd "rm -rf $tempDir"
