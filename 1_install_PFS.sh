#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./1_install_PFS.sh [-help] [-pfsHome=<pfs install location>] [-omsDbName=<OMS DB Name>] [-omsDbHost=<OMS DB Hostname>] [-omsDbPort=<OMS DB Port number>] [-omsDbSSL=<true/false] [-omsDbUsername=<OMS DB Username>] [-omsDbUserPass=<OMS DB Username password>] [-releaseLocation=<Release Bits location>] [-silent] [-jvmMin=<Minimum Java Heap size>] [-jvmMax=<Maximum Java Heap size>] [-propFile=<path to env.properties>] [-removeJMX=<true/false>]

Where
pfsHome : PFS Install location -- Default location :  $HOME/PFS/TEST
omsDbHost : OMS DB Hostname -- Default : 192.168.4.145
omsDbName : OMS DB Name -- Default : LinuxDB
omsDbPort : OMS DB Port Number -- Default : 1433
omsDbUsername : OMS DB Username -- Default : sa
omsDbUserPass : OMS DB Username password -- Default : dhi123\$
omsDbSSL : OMS DB SSL option (specify true or false) - Default : True
jvmMin : Minimum Java Heap size - Default : 1024m
jvmMax : Maximum Java Heap size - Default : 2048m
removeJMX : Remove jmx-console.war, management, admin-console.war and ROOT.war contents from deploy folder -- Default : True
releaseLocation : Release Location -- Default : NONE
silent : Do not prompt for inputs, use default values
propFile : Properties file containing key-value pairs for all the environment details. Command line argument overrides values in properties file.

Eg:
./1_install_PFS.sh -pfsHome=/home/dh/PFS/79212 

./1_install_PFS.sh -pfsHome=/home/dh/PFS/79212 -propFile=/path/to/file/env.properties

./1_install_PFS.sh -pfsHome=/home/dh/PFS/79212 -omsDbHost=192.168.4.6

./1_install_PFS.sh -pfsHome=/home/dh/PFS/79212 -omsDbHost=192.168.4.6 -omsDbName=PFS_LINUX_79212

Note:
The script needs to be run in bash shell

"
	
}


##### Default values 
#	pfsHome="${HOME}/PFS/TEST"
#	omsDbHost="192.168.4.145"
#	omsDbName="LinuxDB"
#	omsDbPort="1433"
#	omsDbUsername="sa"
#	omsDbUserPass="dhi123\$"
#	omsDbSSL="true"


#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
#    VALUE=`echo $1 | awk -F= '{print $2}'`
    VALUE=${1#${PARAM}=}
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
        -skipInstall)
            skipInstall="true"
            ;;
        -silent)
            silent="true"
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        -jvmMin)
            jvmMin=$VALUE
            ;;
        -jvmMax)
            jvmMax=$VALUE
            ;;
        -removeJMX | -removeJMX)
            removeJMX=$VALUE
            ;;
        -omsDbName | -omsDbName)
            omsDbName=$VALUE
            ;;
        -omsDbUserPass)
            omsDbUserPass=$VALUE
            ;;
        -omsDbUsername)
            omsDbUsername=$VALUE
            ;;
        -omsDbSSL)
            omsDbSSL=$VALUE
            ;;
        -omsDbPort)
            omsDbPort=$VALUE
            ;;
        -omsDbHost)
            omsDbHost=$VALUE
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
echo " 		PFS Installation Script"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
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

#
### Starting Time
startTime


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


	if [ "x${pfsHome}" == "x" ]
	then
		getKeyValue "${propFile}" "pfs.home"
		pfsHome=$value
	fi

	if [ "x${omsDbHost}" == "x" ]
	then
		getKeyValue "${propFile}" "db.hostname"
		omsDbHost=$value
	fi


	if [ "x${omsDbName}" == "x" ]
	then
		getKeyValue "${propFile}" "db.name"
		omsDbName=$value
	fi


	if [ "x${omsDbPort}" == "x" ]
	then
		getKeyValue "${propFile}" "db.port" "1433"
		omsDbPort=$value
	fi


	if [ "x${omsDbUsername}" == "x" ]
	then
		getKeyValue "${propFile}" "db.username"
		omsDbUsername=$value
	fi

	if [ "x${omsDbUserPass}" == "x" ]
	then
		getKeyValue "${propFile}" "db.password"
		omsDbUserPass=$value
	fi

	if [ "x${omsDbSSL}" == "x" ]
	then
		getKeyValue "${propFile}" "db.ssl" "true"
		omsDbSSL=$value
	fi

	if [ "x${jvmMin}" == "x" ]
	then
		getKeyValue "${propFile}" "pfs.jvm.heap.min" "1024"
		jvmMin=$value
	fi

	if [ "x${jvmMax}" == "x" ]
	then
		getKeyValue "${propFile}" "pfs.jvm.heap.max" "2048"
		jvmMax=$value
	fi

	if [ "x${removeJMX}" == "x" ]
	then
		getKeyValue "${propFile}" "pfs.remove.jmx-console" "true"
		removeJMX=$value
	fi

### It is silent mode if properties file is used
	silent="true"
fi



if [ "x${silent}" = "x" ]
then
	silent="false"
fi


if [ "x${releaseLocation}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the Release location :"
	read releaseLocation
	echo
fi


### Let us try to prompt the user for PFS_HOME, OMS DB and OMS DB Hostname in case not provided as a parameter

if [ "x${pfsHome}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the PFS_HOME Location [Default : $HOME/PFS/TEST]:"
	read pfsHome
fi

echo
echo


if [ "x${omsDbHost}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the OMS DB Hostname [Default : 192.168.4.145]:"
	read omsDbHost
fi


if [ "x${omsDbPort}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the OMS DB Port Number  [Default : 1433]:"
	read omsDbPort
fi

if [ "x${omsDbSSL}" == "x" ] && [ "$silent" == "false" ] 
then
	echo
	echo
	echo "Is OMS DB running in SSL mode (true/false) ? [Default : true] : "
	read omsDbSSL
fi


if [ "x${omsDbName}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the OMS DB Name [Default : LinuxDB] :"
	read omsDbName
fi

if [ "x${omsDbUsername}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the OMS DB Username [Default : sa]:"
	read omsDbUsername
fi

if [ "x${omsDbUserPass}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the OMS DB Username password [Default : dhi123\$]:"
	read omsDbUserPass
fi


if [ "x${jvmMin}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the Java Heap size Minimum value [Default : 1024m]:"
	read jvmMin
fi

if [ "x${jvmMax}" == "x" ] && [ "$silent" == "false" ]
then
	echo
	echo
	echo "Enter the Java Heap size Maximum value [Default : 2048m]:"
	read jvmMax
fi

### Use the default values in case still not provided
if [ "x${pfsHome}" == "x" ]
then
	pfsHome="${HOME}/PFS/TEST"
	echo "INFO: PFS_HOME location is not provided, using the default location $pfsHome"
else
	echo "Using PFS_HOME location provided - $pfsHome"
fi

echo

### Use the default OMS DB if not passed to the script
if [ "x${omsDbName}" == "x" ]
then
	omsDbName="LinuxDB"
	echo "INFO: OMS DB Name is not provided, using the default DB $omsDbName"
else
	echo "Using OMS DB name provided - $omsDbName"
fi

echo
if [ "x${omsDbPort}" == "x" ]
then
	omsDbPort="1433"
	echo "INFO: OMS DB Port Number is not provided, using the default DB $omsDbPort"
else
	echo "Using OMS DB Port Number provided - $omsDbPort"
fi

echo

if [ "x${omsDbSSL}" == "x" ]
then
	omsDbSSL="true"
	echo "INFO: OMS DB SSL value is not provided, assuming it to be running in SSL - Value : $omsDbSSL"
else
	echo "Using OMS DB SSL value provided - $omsDbSSL"
fi

echo

if [ "x${omsDbUsername}" == "x" ]
then
	omsDbUsername="sa"
	echo "INFO: OMS DB Username is not provided, using the default username $omsDbUsername"
else
	echo "Using OMS DB Username provided - $omsDbUsername"
fi

echo

if [ "x${omsDbUserPass}" == "x" ]
then
	omsDbUserPass="dhi123\$"
	echo "INFO: OMS DB Username password is not provided, using the default password $omsDbUserPass"
else
	echo "Using OMS DB Username password provided - $omsDbUserPass"
fi

echo



if [ "${omsDbSSL}" == "true" ]
then
	omsDbSSL="mandatory"
else
### auto  for non-SSL
	omsDbSSL="auto"
fi

if [ "x${omsDbHost}" == "x" ]
then
	omsDbHost="192.168.4.145"
	echo "INFO: OMS DB Hostname is not provided, using the default DB Hostname $omsDbHost"
else
	echo "Using OMS DB Hostname provided - $omsDbHost"
fi

echo
if [ "x${jvmMin}" == "x" ]
then
	jvmMin="1024"
	echo "INFO: Java Heap Size Minimum value is not provided, using the default value ${jvmMin}m"
else
	echo "Using Java Heap Size Minimum value provided - ${jvmMin}m"
fi

echo

if [ "x${jvmMax}" == "x" ]
then
	jvmMax="2048"
	echo "INFO: Java Heap Size Maximum value is not provided, using the default value ${jvmMax}m"
else
	echo "Using Java Heap Size Maximum value provided - ${jvmMax}m"
fi

echo


### Exit the script if releaseLocation is NOT PASSED in -silent mode
if [ "x${releaseLocation}" == "x" ]
then
	echo
	echo "ERROR : Release location is a mandatory requirement for the script. No default value is available"
	echo
	exit 1
fi

printf "Release location : $releaseLocation\n"

jdkZip="${releaseLocation}/MISC/jdk1.6.0_17.zip"

currUser=`whoami`

if [ ! -r $jdkZip ]
then
	echo
	echo "ERROR : Unable to read $jdkZip";
	echo
	exit 1
fi

### Yeh. Found jdkZip, let us unzip it @ /home/dh (hardcoded location as it is a prereq for the installer)

echo
echo "Found $jdkZip, unzipping under /home/dh....."
echo

jdkDir="/home/dh/jdk1.6.0_17"

if [ "x${skipInstall}" == "x" ]
then
	backupFile $jdkDir

	runCmd "mkdir -p $jdkDir"

	runCmd "unzip -qod $jdkDir $jdkZip"

	runCmd  "chmod -R 777 $jdkDir"
fi


##########################################################################################

date=`date`
### Let us skip the install, on need basis

if [ "x${skipInstall}" == "x" ]
then
	backupFile $pfsHome 

	runCmd "mkdir -p $pfsHome"

	runCmd "chmod -R 755 $pfsHome"
fi


installProp="/tmp/installer.properties_${datestamp}"

echo
echo "Creating installer.properties file....."
echo

echo "
#$date
WLMS_ROOT_DIRECTORY=
TEMP_DIR=/tmp
WLS_LISTENING_PORT=8080
HOST_NAME=$omsDbHost
WLMS_JAVA_HOME=
ADMIN_SERVER_NAME=
STANDALONE_SERVER_INSTALL=1
SQL_SERVER=1
USER_INSTALL_DIR_CONTENTS_NEED_TO_BE_DELETED=
FRESH_PFS_INSTALL_SCENARIO=1
WLMS_INSTALL_HOME=
WLS_DOMAIN_SERVER_NAME=
SSLTrusted=false
PDF_DOCS_PRESENT=
PFS_INSTALL=1
WLS_HOME=
EXTRACTOR_DIR=${releaseLocation}/PFS
JPROXY_INSTALL=1
JVM_MAX=${jvmMax}
PFS_DOMAIN_NAME=
INSTALL_JACKRABBIT=0
WLMS_MACHINE_NAME=
USER_INSTALL_DIR=${pfsHome}
WLMS_LIST_ADDRESS=
DHARBOR_SECURITY_PROVIDER_ORDINATION=
SOLARIS_USERNAME=$currUser
SSL=${omsDbSSL}
VERIFY_ADMIN_PASSWORD=password
DATABASE_NAME=$omsDbName
USER_MAGIC_FOLDER_2=
USER_MAGIC_FOLDER_1=/tmp/160748.tmp/pfs_installer_resources
EMAIL_ADDRESS=
USER_IS_NOT_ROOT_USER=
DB_TYPE=SQL Server
PASSWORD=${omsDbUserPass}
API_INSTALL=1
READ_ME_FILE_PRESENT=
WLMS_DOMAIN_NAME=
ADMIN_SVC_RESTARTER_REGISTRY_PORT=1099
PFS_DOMAIN_LOCATION=${pfsHome}
PORT_NUMBER=${omsDbPort}
USERNAME=${omsDbUsername}
WLMS_BEA_HOME=
PFS_AUTOSTART=
ORACLE=
ADMIN_PASSWORD=password
ADMIN_SERVER_INSTALL=0
OLD_SHORTCUTS_FOLDER=
USER_SHORTCUTS=Do_Not_Install
ADMIN_USERNAME=admin
REMOTE_ADMIN_CONSOLE_INSTALL=1
MANAGED_SERVER_NAME=
MAIL_SERVER_NAME=
EMAIL_SUBJECT=Message from PFS server
WLS_LIST_ADDRESS=
DOCUMENT_VIEWER_INSTALL=0
WLMS_LIST_PORT=
UPDATE_PFS_INSTALL_SCENARIO=
JVM_MIN=${jvmMin}
SDK_HOME=
REMOTE_ADMIN_CONSOLE_JAVA_HOME=/jre
MANAGED_SERVER_INSTALL=
WLS_VERSION=

" > $installProp

echo "Done."
echo

echo "Installer properties file : $installProp"
echo

### Now launch the installer in silent mode

installerBinary="${releaseLocation}/PFS/PFS_JBossSetupJDK6.bin"

### Check the installer binary exists

echo
echo "Launching the PFS installer....."
echo

if [ ! -r $installerBinary ]
then
	echo
	echo "ERROR : Unable to read $installerBinary"
	echo 
	echo "Please ensure that the binary exists and has execute permissions."
	echo
	exit 1

fi

runCmd "chmod 755 $installerBinary"

export JAVA_HOME=$jdkDir
export PATH=$JAVA_HOME/bin:$PATH

echo
echo "JAVA_HOME=$JAVA_HOME"
echo "PATH=$PATH"
echo

which java

java -version


cmd="$installerBinary -i silent -f $installProp"

echo
echo "Running the command : $cmd"
echo
echo

exitCode=$?

### Comment it out
if [ "x${skipInstall}" == "x" ]
then
	$cmd
	exitCode=$?
fi


echo
echo "PFS Installer Exit Code : $exitCode"
echo


### Exit the script if installation is not successful.
if [ $exitCode -ne 0 ]
then
	echo
	echo "ERROR : PFS installation Failed."
	echo
	echo "Please check the log files @ $pfsHome"
	echo
	exit $exitCode
fi

runCmd "chmod -R 755 ${pfsHome}"


### Let us remove the jmx-console and other JBoss default WARs
if [ $removeJMX == "true" ]
then
	echo
	echo "Removing jmx-console.war, management, admin-console.war and ROOT.war contents"
	echo
	
	runCmd "ls ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/jmx-console.war"
	runCmd "rm -rf ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/jmx-console.war"

	runCmd "ls ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/admin-console.war"
	runCmd "rm -rf ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/admin-console.war"

### Don't delete index.html	
	runCmd "cp ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/ROOT.war/index.html /tmp"
	runCmd "ls ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/ROOT.war"
	runCmd "rm -rf ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/ROOT.war/*"
	runCmd "cp /tmp/index.html ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/ROOT.war/index.html"

	runCmd "ls ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/management"
	runCmd "rm -rf ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/management"
fi

echo 
echo "Creating the startup script ....."
echo
startupScript="${pfsHome}/jboss-5.1.0.GA/bin/start.sh"
echo "sh run.sh -Djboss.bind.address=0.0.0.0" > $startupScript


### Update run.sh with the actual installed JAVA_HOME and JBOSS_HOME_PATH locations

JBOSS_HOME_PATH="${pfsHome}/jboss-5.1.0.GA" 

runShScript="${JBOSS_HOME_PATH}/bin/run.sh"


echo
echo "Updating run.sh with actual JAVA_HOME and JBOSS_HOME_PATH ....."
echo

echo
echo "Let us backup the run.sh file before updating it ....."
echo
cmd="cp $runShScript ${runShScript}_${datestamp}"
echo "Running the command :"
echo $cmd
$cmd 
echo



### Update JAVA_HOME

JAVA_HOME="${pfsHome}/jdk1.6.0_17"


echo
echo "Updating run.sh with JAVA_HOME ....."
echo

while read line
do
	echo $line | grep ^\s*JAVA_HOME= >/dev/null
	if [ $? -eq 0 ]
	then
		echo
		echo "OLD LINE:"
		echo "$line"
		echo
		echo
		newLine="JAVA_HOME=$JAVA_HOME"
		echo "UPDATED LINE:"
		echo "$newLine"
		echo

### Replace the line using perl inline option
		echo "perl -p -i -e 's+$line+$newLine+g' $runShScript" > /tmp/${datestamp}_cmd.sh
		chmod 755 /tmp/${datestamp}_cmd.sh
		echo "Running the command :"
		cat /tmp/${datestamp}_cmd.sh
		/tmp/${datestamp}_cmd.sh

### Now, break out of the while loop
		break
	fi 
done <${runShScript}_${datestamp}


### Update JBOSS_HOME_PATH

echo
echo "Updating run.sh with JBOSS_HOME_PATH ....."
echo

while read line
do
	echo $line | grep ^\s*JBOSS_HOME_PATH= >/dev/null
	if [ $? -eq 0 ]
	then
		echo
		echo "OLD LINE:"
		echo "$line"
		echo
		echo
		newLine="JBOSS_HOME_PATH=$JBOSS_HOME_PATH"
		echo "UPDATED LINE:"
		echo "$newLine"
		echo

### Replace the line using perl inline option
		echo "perl -p -i -e 's+$line+$newLine+g' $runShScript" > /tmp/${datestamp}_cmd.sh
		chmod 755 /tmp/${datestamp}_cmd.sh
		echo "Running the command :"
		cat /tmp/${datestamp}_cmd.sh
		/tmp/${datestamp}_cmd.sh
### Now, break out of the while loop
		break
	fi 
done <${runShScript}_${datestamp}

echo "Done."
echo


### Update the JVM heap sizes directly as silent installer doesn't seem to update them
# #JAVA_OPTS="$JAVA_OPTS -Xms1024m -Xmx2048m -XX:MaxPermSize=950M"

replaceText "${runShScript}" "Xms1024m" "Xms${jvmMin}m"
replaceText "${runShScript}" "Xmx2048m" "Xmx${jvmMax}m"



echo 
echo "Environment Details :"
echo "====================="
echo "PFS_HOME : $pfsHome"
echo "JAVA_HOME : $JAVA_HOME"
echo "Startup script : $startupScript"
echo "Command :"
cat $startupScript


adminPrefs="${pfsHome}/jboss-5.1.0.GA/server/default/admin.prefs"

if [ -r $adminPrefs ]
then
	echo
	echo "Contents of $adminPrefs file : "
	echo "=============================="
	echo
	cat $adminPrefs
	echo
	echo
else
	echo
	echo "ERROR : Unable to read $adminPrefs file."
fi


#
### END
#
endTime


### Now exit gracefully
exit 0
