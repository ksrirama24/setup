#!/bin/bash

#######################################################################
#
# 8th Dec 2016 - ksrirama - Initial Version
#
#
#
#

#######################################################################

#
### Usage Function
#
usage()
{
	echo "
Usage :
./mongoDB_details.sh [-help] [-mongoTop=<pfs install location>] 

Where:
mongoTop : MongoDB Install top location -- Default : NONE 

Eg:
./mongoDB_details.sh -mongoTop=/home/dh/PFS/79212 


Note:
The script needs to be run in bash shell

"
	
}

checkBash()
{
        if [ "X${BASH}" != "X/bin/bash" ]
        then
                echo
                echo "ERROR: Script requires to be run in bash shell. Please run it as ./<script_name> or use bash"
                echo
                exit 1
        else
                echo
                echo "INFO: Running in $SHELL shell"
                echo
        fi


} #Function to check bash



### Function to run an OS command
runCmd()
{
        command="$1"
        echo
        echo "Running the command : $command"
        $command
        RC=$?
        if [ $RC -ne 0 ]
        then
                echo
                echo "ERROR : Failed to run the command $command "
                echo "Exit code : $RC"
                echo
                exit $RC
        fi
        echo "Done."
        echo
        return $RC
}
# End of runCmd()




### Start time

startTime()
{
        date=`date`
        echo
        echo "Script Start time : $date"
        echo
}

### End time

endTime()
{
        date=`date`
        echo
        echo "Script End time : $date"
        echo
}




### Function to return Value of a Key
#
# Returns first value found in the properties file
#
getKeyValue()
{
        propFile=$1
        key=$2
#       value=`grep ^$key $propFile | head -1 | awk -F'=' '{print \$2}'`
        value=`grep ^$key $propFile | head -1`
        value=${value#${key}=}
        defaultValue=$3

### Delete spaces
        value=`echo $value | sed 's+\s*++g'`

        if [ "x${value}" == "x" ] && [ "x${defaultValue}" == "x" ]
        then
                echo
                echo "ERROR: Value of $key is NOT defined in the properties file."
                echo
                exit 1
        fi

### Set default value
        if [ "x${value}" == "x" ]
        then
                value=$defaultValue
        fi


} # End of function getKeyValue





datestamp=`date +%Y-%b-%d_%H-%M-%S-%N`
mkdir /tmp/$datestamp

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
        -mongoTop)
            mongoTop=$VALUE
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
echo " 		MongoDB Environment Details: "
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


### Let us try to prompt the user for PFS_HOME in case not provided as a parameter

if [ "x${mongoTop}" == "x" ]
then
	echo
	echo
	echo "Enter the MongoDB Top Location [Default : /data/MongoDB]:"
	read mongoTop
fi

echo
echo


### Use the default values in case still not provided
if [ "x${mongoTop}" == "x" ]
then
	mongoTop="/data/MongoDB"
	echo "INFO: MongoDB top location is not provided, using the default location $mongoTop"
else
	echo "INFO: Using MongoDB top location provided - $mongoTop"
fi
echo


#
### For patch installer, let us use the JDK present under the PFS_HOME

if [ ! -d $mongoTop ]
then
	echo
	echo "ERROR: Unable to read the MongoDB top directory $mongoTop"
	echo
	exit 1
fi


### Server details
host=`hostname`
ipAddress=`ifconfig eth0| grep inet | head -1 | sed 's+inet addr:++g'| awk '{print \$1}'`
printf "%-50s %s \n" "Hostname" ": $host"
#Name="Hostname"
#printf "%s %s %s \n" "$Name" "${padLine:${#Name}}" ": $host"
printf "%-50s %s \n" "Machine IP Address" ": $ipAddress"
echo
echo "Contents of /etc/hosts :"
echo "------------------------"
cat /etc/hosts
echo "----------------------------------------------------------"


### Checkc if java from PFS_HOME is running
mongoHome="${mongoTop}/mongodb/mongodb-linux-x86_64-ubuntu1404-3.2.4"
echo
printf "%-50s %s\n" "MongoDB Home " ": $mongoHome"


startScript="${mongoHome}/bin/mongoDB_start.sh"

if [ ! -f $startScript ]
then
	echo
	echo "WARNING: mongoDB_start.sh NOT FOUND at $startScript"
	echo
else
	echo
	echo "Start script (mongoDB_start.sh) contents :"
	echo "------------------------------------------"
### Exclude the commented lines and blank lines
	sed 's+^\s*#.*++g;/^$/d' $startScript
	echo "--------------------------------------------------------------------------"
fi

mongoShell="${mongoHome}/bin/mongoShell_start.sh"

## Exclude the export command as well
shellCmd=`sed 's+^\s*#.*++g;/^$/d;s+^\s*export.*$++g' $mongoShell`
shellCmd="$shellCmd --quiet"

### Set PATH
export PATH=${mongoHome}/bin:$PATH

mongoJs="/tmp/${datestamp}/mongo.js"

### Hostname in MongoDB 

echo
echo
echo "Getting details from the Mongo DB ....."
echo

echo "DB Startup Arguments used :"
$shellCmd admin --eval 'db.runCommand("getCmdLineOpts").argv'
echo

value=`$shellCmd --eval 'db.serverStatus().host'`
printf "%-50s %s\n" "Hostname" ": $value"


value=`$shellCmd --eval 'db.serverStatus().version'`
printf "%-50s %s\n" "DB Version" ": $value"


value=`$shellCmd --eval 'db.serverStatus().process'`
printf "%-50s %s\n" "DB Process" ": $value"

value=`$shellCmd --eval 'db.serverStatus().uptime / 3600'`
printf "%-50s %s\n" "Server Uptime" ": $value Hours"

value=`$shellCmd --eval 'db.serverStatus().localTime'`
printf "%-50s %s\n" "Current Time" ": $value"

echo
echo
### Find the Disk Space. We need to run the command on admin DB
dataDir=`$shellCmd -eval 'db._adminCommand("getCmdLineOpts").parsed.storage.dbPath'`
printf  "%-50s %s\n" "Data Directory" ": $dataDir"

value=`du -sh $dataDir | awk '{print $1}'`
printf  "%-50s %s\n" "Data Directory Size" ": $value"

printf  "%-50s \n" "Data Directory File System details :"
df -h $dataDir

### Get the Disk Space on the dataPath

echo
echo
value=`$shellCmd --eval 'db.serverStatus().mem.virtual'`
printf "%-50s %s\n" "Memory Used by the DB" ": $value MB"


echo
echo
echo "Database Size (in MB):"
echo "----------------------"
echo "db._adminCommand('listDatabases').databases.forEach(function (d) {
mdb = db.getSiblingDB(d.name);
print(mdb.stats().db, '\t', mdb.stats(1024*1024).dataSize);
})
" >$mongoJs

$shellCmd < $mongoJs

echo
echo
value=`$shellCmd --eval 'db.serverStatus().connections.current'`
printf "%-50s %s\n" "Current active connections" ": $value"

value=`$shellCmd --eval 'db.serverStatus().connections.totalCreated' | awk -F'(' '{print $2}' | awk -F')' '{print $1}'`
printf "%-50s %s\n" "Total Connections created since uptime" ": $value"

value=`$shellCmd --eval 'db.serverStatus().connections.available'`
printf "%-50s %s\n" "Max connections that can be served by the DB" ": $value"

echo 
echo 
echo "Memory Allocation Details :"
$shellCmd --eval 'db.serverStatus().tcmalloc.formattedString'


#### Replica Set Configuration details

### First check if the DB is part of Replica Set

echo
echo "Replication Configuration:"
echo "--------------------------"

value=`$shellCmd --eval 'rs.status()'`

if [[ $value == *"not running with --replSet"* ]]
then
	echo
	echo "WARNING: MongoDB instance is NOT running in Replica Set Mode." 
	echo
else
        echo
	echo "INFO: MongoDB instance is running in Replica Set Mode"
	echo
### Print the status of the Replica Set
$shellCmd --eval 'rs.status()'
	
fi



### Remove the tmp folder
rm -rf /tmp/${datestamp}

echo
#
### END
#
endTime


### Now exit gracefully
exit 0
