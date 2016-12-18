#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./RSPD_settings.sh [-help] [-pfsHome=<pfs install location>] 

Where:
pfsHome : PFS Install location -- Default location :  $HOME/PFS/TEST

Eg:
./RSPD_settings.sh 

./RSPD_settings.sh -pfsHome=/home/dh/PFS/79212 


Note:
The script needs to be run in bash shell

"
	
}


#
### Parse the command line arguments
#
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | -help)
            usage
            exit
            ;;
        -pfsHome)
            pfsHome=$VALUE
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
echo " 		RSPD settings script"
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

### Let us try to prompt the user for PFS_HOME, OMS DB and OMS DB Hostname in case not provided as a parameter

if [ "x${pfsHome}" == "x" ]
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

cmd="$installerBinary -i silent -f $installProp"

echo
echo "Running the command : $cmd"
echo
echo


#
### END
#
endTime


### Now exit gracefully
exit 0
