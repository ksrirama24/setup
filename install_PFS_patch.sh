#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./install_PFS_patch.sh [-help] [-pfsHome=<pfs install location>] [-docViewer=<true/false>] [-releaseLocation=<Release Bits location>] [-silent]

Where:
pfsHome : PFS Install location -- Default location :  $HOME/PFS/TEST
docViewer : Install Doc Viewer (true or false) -- Default : false
releaseLocation : Release Location -- Default : NONE
silent : Do not prompt for inputs, use default values

Eg:
./install_PFS_patch.sh -pfsHome=/home/dh/PFS/79212 

./install_PFS_patch.sh -pfsHome=/home/dh/PFS/79212 -omsDbHost=192.168.4.6

./install_PFS_patch.sh -pfsHome=/home/dh/PFS/79212 -omsDbHost=192.168.4.6 -omsDbName=PFS_LINUX_79212

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
        -releaseLocation)
            releaseLocation=$VALUE
            ;;
        -silent)
            silent="true"
            ;;
        -pfsHome)
            pfsHome=$VALUE
            ;;
        -docViewer)
            docViewer=$VALUE
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


### Use the default values in case still not provided
if [ "x${pfsHome}" == "x" ]
then
	pfsHome="${HOME}/PFS/TEST"
	echo "INFO: PFS_HOME location is not provided, using the default location $pfsHome"
else
	echo "Using PFS_HOME location provided - $pfsHome"
fi

echo

### Doc viewer 
if [ "x${docViewer}" == "xtrue" ]
then
	docViewer="1"
else
	docViewer="0"
fi

if [ "x${docViewer}" == "x" ]
then
	docViewer="0"
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


#
### For patch installer, let us use the JDK present under the PFS_HOME

if [ ! -d $pfsHome ]
then
	echo
	echo "ERROR: Unable to read the PFS_HOME directory $pfsHome."
	echo
	exit 1
fi

javaHome="${pfsHome}/jdk1.6.0_17"

if [ ! -x "${javaHome}/bin/java" ]
then
	echo
	echo "ERROR: Unable to find java executable at ${javaHome}/bin/java" 
	echo
	exit 1
fi


##########################################################################################


#
### Check and exit if the server is running 
#
serverProcess=`ps -ef | grep ${javaHome}/bin/java |grep -v grep`

if [ "x${serverProcess}" != "x" ]
then
	echo
	echo "ERROR: Server is still running in the memory. Please stop the server before proceeding."
	echo
	echo "Server Process : "
	echo "$serverProcess"
	echo
	exit 1

fi

#
### Backup the default directory before applying the patch
#

echo
echo "Let us backup the default folder before applying the patch....."
echo
backupFile "${pfsHome}/server/default"


date=`date`


installProp="/tmp/patch.properties_${datestamp}"

echo
echo "Creating patch.properties file....."
echo

echo "
#$date
#Choose Patch Types
#------------------
APPLY_PFS_PATCH=1
DOCUMENT_VIEWER_INSTALL=${docViewer}

#Choose PFS Update Target Directory
#----------------------------------
PFS_DOMAIN=${pfsHome}

" > $installProp

echo "Done."
echo

echo "Installer properties file : $installProp"
echo

### Now launch the installer in silent mode

installerBinary="${releaseLocation}/PFS/PiiEUpdate.bin"

### Check the installer binary exists

echo
echo "Launching the PFS Patch Installer....."
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

export JAVA_HOME=$javaHome
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
$cmd
exitCode=$?


echo
echo "PFS Patch Installer Exit Code : $exitCode"
echo


### Exit the script if installation is not successful.
if [ $exitCode -ne 0 ]
then
	echo
	echo "ERROR : PFS Patch installation Failed."
	echo
	echo "Please check the log files @ $pfsHome"
	echo
	exit $exitCode
fi

echo 
echo "Environment Details :"
echo "====================="
echo "PFS_HOME : $pfsHome"
echo "JAVA_HOME : $javaHome"


#
### END
#
endTime


### Now exit gracefully
exit 0
