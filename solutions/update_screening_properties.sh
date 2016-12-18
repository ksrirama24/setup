#!/bin/bash


#
### Usage Function
#
usage()
{
	echo "
Usage :
./update_screening_properties.sh [-help] [propFile=<path to env.properties files>] 

Where:
propFile : Path to env.properties file 

Eg:
./update_screening_properties.sh 

./update_screening_properties.sh -propFile=/path/to/file/env.properties

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
        -propFile)
            propFile=$VALUE
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
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " 		Script to update screening.properties"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
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

scriptDir=`dirname ${scriptDir}`

echo "Script dir : $scriptDir"

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


if [ "x${propFile}" == "x" ]
then

	echo
	echo
	echo "Enter the env.properties location :"
	read propFile
fi



if [ ! -r $propFile ]
then
	echo
	echo "ERROR: Unable to read properties file at $propFile"
	echo
	exit 1
fi


echo
echo
echo "Property file supplied : $propFile"
echo
echo
if [ ! -r $propFile ]
then
	echo
	echo "ERROR: Unable to read properties file $propFile"
	echo
	exit 1
fi

getKeyValue "$propFile" "pfs.home"
pfsHome=$value
	

if [ "x${pfsHome}" == "x" ]
then
	echo
	echo "ERROR: Unable to read PFS_HOME location from properties file "
	echo
	exit 1
fi

echo
echo
echo "Environment Details :"
echo
echo "PFS_HOME : $pfsHome"


echo
echo


#
### For patch installer, let us use the JDK present under the PFS_HOME

if [ ! -d $pfsHome ]
then
	echo
	echo "ERROR: Unable to read the PFS_HOME directory $pfsHome."
	echo
	exit 1
fi

screeningPropFile="${pfsHome}/jboss-5.1.0.GA/server/default/conf/screening.properties"


if [ ! -r "${screeningPropFile}" ]
then
	echo
	echo "ERROR: Unable to read screening.properties at  ${screeningPropFile}" 
	echo
	exit 1
fi

### Get the Prizm IP from properties file

getKeyValue "$propFile" "prizm.hostname" 
prizmHost=$value

# DOCVIEWER_IP_ADDRESS=192.168.4.22
updatePairValue "$screeningPropFile" "DOCVIEWER_IP_ADDRESS" "$prizmHost"

#
### END
#
endTime


### Now exit gracefully
exit 0
