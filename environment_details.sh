#!/bin/bash

###########################################################################
#
# 8th Dec 2016 - ksrirama - Added support for AccountHistoryProcess.jar, ACcountHistoryApp.war, CaseSummary.war, 
#			    Data Sources Pool Sizes and  DMS Configurations
#
#
#
###########################################################################

#
### Usage Function
#
usage()
{
	echo "
Usage :
./environment_details.sh [-help] [-pfsHome=<pfs install location>] 

Where:
pfsHome : PFS Install location -- Default : NONE 

Eg:
./environment_details.sh -pfsHome=/home/dh/PFS/79212 


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
echo " 		PFS Environment Details: "
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

### Check for all the utilities required for the script

which xmllint >/dev/null

if [ $? -eq 1 ]
then
	echo
	echo "ERROR: xmllint is NOT available in the system. Please install it and re-run the script."
	echo "You can use the command \"apt-get install libxml2-utils\" to install xmllint."
	echo
	exit 1
fi



### Let us try to prompt the user for PFS_HOME in case not provided as a parameter

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
	echo "INFO: Using PFS_HOME location provided - $pfsHome"
fi
echo


#
### For patch installer, let us use the JDK present under the PFS_HOME

if [ ! -d ${pfsHome}/jboss-5.1.0.GA ]
then
	echo
	echo "ERROR: Unable to read the jboss-5.1.0.GA directory at ${pfsHome}/jboss-5.1.0.GA"
	echo
	exit 1
fi


padLine=".................................................."

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

echo
printf "%-50s %s\n" "PFS_HOME " ": $pfsHome"

pfsJava="${pfsHome}/jdk1.6.0_17/bin/java"

printf "%-50s %s\n" "PFS Java Version " ":"
$pfsJava -version

startScript="${pfsHome}/jboss-5.1.0.GA/bin/start.sh"

if [ ! -f $startScript ]
then
	echo
	echo "WARNING: start.sh NOT FOUND at $startScript"
	echo
else
	echo
	echo "Start script (start.sh) contents :"
	echo "----------------------------------"
	sed 's+^\s*#.*++g;/^$/d' $startScript
	echo "--------------------------------------------------------------------------"
fi

# JVM Heap Size
	jvmLine=`grep Xms $pfsHome/jboss-5.1.0.GA/bin/run.sh | grep -v ^# | head -1`
	echo
	printf "%-50s %s\n" "JVM Heap size in run.sh" ": $jvmLine"

echo
echo
echo "=========================================================================================="
echo
echo
echo "SSL and SSO configurations:"
echo "---------------------------"

# SSL Configurations 
echo
echo "SSL Configurations:"
echo "-------------------"
sslFlag=`xmllint -xpath '/Server/Service/Connector/@SSLEnabled' ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/jbossweb.sar/server.xml`

if [ "$sslFlag" == "XPath set is empty" ]
then
	echo "SSL is DISABLED in server.xml"
else
	printf "%-50s %s\n" "SSL attribute in server.xml" ": $sslFlag"
fi

jbossserverhomedir="${pfsHome}/jboss-5.1.0.GA/server/default"

identityJksPath=`xmllint -xpath '/Server/Service/Connector/@keystoreFile' ${pfsHome}/jboss-5.1.0.GA/server/default/deploy/jbossweb.sar/server.xml`
identityJks=`echo $identityJksPath|awk -F '\/' '{print \$NF}'| sed 's+\"++g'`
printf "%-50s %s \n" "Keystore file in server.xml" ": $identityJks"

identityJks="${pfsHome}/jboss-5.1.0.GA/server/default/conf/${identityJks}"


if [ ! -f $identityJks ]
then
	echo
	echo "ERROR: Keystore file is NOT FOUND at $identityJks"
	echo
fi

### Let's get the contents of identity.jks

### Let's use the Java from PFS

cmd="${pfsHome}/jdk1.6.0_17/bin/keytool -v -list -keystore $identityJks -storepass password"

echo "Running the command : "
echo $cmd

$cmd



### Check whether the certificate is imported in cacerts
cert=`${pfsHome}/jdk1.6.0_17/bin/keytool  -list -keystore ${identityJks} -storepass password | grep 'Certificate fingerprint'`


${pfsHome}/jdk1.6.0_17/bin/keytool  -list -keystore ${pfsHome}/jdk1.6.0_17/jre/lib/security/cacerts -storepass changeit | grep "$cert" >/dev/null 2>&1
if [ $? -eq 0 ]
then
	echo "INFO: PFS certificate is imported in JDK cacerts"
else
	echo "ERROR: PFS certificate is NOT imported in JDK cacerts"
fi



### Get the picketlink URL from default.cfg
#/home/dh/PFS/PFS_B25/PFS/jboss-5.1.0.GA/server/default/conf/default.cfg
#picketlinkSTS.Webservice.endpointURI=https://192.168.4.7:8443/picketlink-sts-1.0.0/PicketLinkSTS



### picketlink.war 
#      WEB-INF/classes/picketlink-sts.xml
#      WEB-INF/web.xml
#      WEB-INF/wsdl/PicketLinkSTS.wsdl
#      WEB-INF/classes/identity.jks

picketLinkWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/picketlink-sts-1.0.0.war"
ssoWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/sso.war"
screeningProps="${pfsHome}/jboss-5.1.0.GA/server/default/conf/screening.properties"
accHistAppWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/AccountHistoryApp.war"
accHistJar="${pfsHome}/jboss-5.1.0.GA/server/default/lib/AccountHistoryProcess.jar"
caseSummaryWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/CaseSummary.war"
prizmWar="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/oms/applications/prizmccplusjsp.war"
adminPrefs="${pfsHome}/jboss-5.1.0.GA/server/default/admin.prefs"
adminPrefs_conf="${pfsHome}/jboss-5.1.0.GA/server/default/conf/admin.prefs"
systemPrefs_conf="${pfsHome}/jboss-5.1.0.GA/server/default/conf/system.prefs"
systemPrefs_app_KYP="${pfsHome}/jboss-5.1.0.GA/server/default/app/KYP/system.prefs"
systemPrefs_app="${pfsHome}/jboss-5.1.0.GA/server/default/app/system.prefs"
modelXML="${pfsHome}/jboss-5.1.0.GA/server/default/oms/model/KYP.xml"
pmfConfProp="${pfsHome}/jboss-5.1.0.GA/server/default/conf/PMFconfig.properties"
usermanagerProps="${pfsHome}/jboss-5.1.0.GA/server/default/conf/usermanager.properties"
quartzProps="${pfsHome}/jboss-5.1.0.GA/server/default/conf/quartz.properties"
docViewerCfg="${pfsHome}/jboss-5.1.0.GA/server/default/conf/documentviewer.cfg"
dmsConfProp="${pfsHome}/jboss-5.1.0.GA/server/default/conf/dms-configuration.properties"

picketTmp="/tmp/${datestamp}/picket"
mkdir -p $picketTmp

unzip -qod $picketTmp $picketLinkWar WEB-INF/classes/picketlink-sts.xml
unzip -qod $picketTmp $picketLinkWar WEB-INF/web.xml
unzip -qod $picketTmp $picketLinkWar WEB-INF/wsdl/PicketLinkSTS.wsdl
unzip -qod $picketTmp $picketLinkWar WEB-INF/classes/identity.jks

### We will unzip sso.war here to consolidate PicketlinkURL values
ssoTmp="/tmp/${datestamp}/sso"
unzip -qod $ssoTmp $ssoWar WEB-INF/config.properties
confProp="${ssoTmp}/WEB-INF/config.properties"


picketLinkStsXml="${picketTmp}/WEB-INF/classes/picketlink-sts.xml"
picketLinkStsXmlNoComments="${picketTmp}/WEB-INF/classes/picketlink-sts_no_comments.xml"
picketLinkWebXml="${picketTmp}/WEB-INF/web.xml"
picketLinkStsWsdl="${picketTmp}/WEB-INF/wsdl/PicketLinkSTS.wsdl"

# picketlink-sts.xml

### Remove the comments from XML
cat $picketLinkStsXml | sed '/<!--.*-->/d' | sed '/<!--/,/-->/d' > $picketLinkStsXmlNoComments

grep org.picketlink.identity.federation.core.impl.KeyStoreKeyManager $picketLinkStsXmlNoComments >/dev/null


if [ $? -ne 0 ]
then
	echo
	echo "INFO: KeyProvider is not defined in Picketlink XML"
	echo
else
	echo
	echo "KeyProvider section in Prcketlink XMl :"
	echo "---------------------------------------"
	flag="0"

while IFS='' read -r line || [[ -n "$line" ]];
do
        echo $line | grep KeyProvider  >/dev/null
        if [ $? -eq 0 ]
        then
                if [ "$flag" == "1" ]
                then
                        flag="0"
### We have to print the last line as flag gets flipped
                        echo $line
                elif [ "$flag" == "0" ]
                then
                        flag="1"
                fi
        fi

        if [ "$flag" == "1" ]
        then
                echo $line
        fi
### Get the name of the Keystore file 
### <Auth Key="KeyStoreURL" Value="identity.jks"/>
	echo $line | grep KeyStoreURL >/dev/null 	
	if [ $? -eq 0 ]
	then
		picketLinkJksName=`echo $line | sed 's+.*Value="++g;s+".*++g'`
	fi	
done <$picketLinkStsXmlNoComments

echo
printf "%-50s %s" "JKS file in Picketlink " ": $picketLinkJksName"
echo

if [ "x${picketLinkJksName}" == "x" ]
then
	echo "ERROR: Unable to get Keystore file name from picketlink-sts.xml"
else
	picketLinkJks="${picketTmp}/WEB-INF/classes/${picketLinkJksName}"
### Compare identity.jks in picketlink war and in conf

	echo
	echo "Comaparing the Keystore file from picketlink WAR and from server.xml ....."
	echo
	cmd="diff $picketLinkJks $identityJks"
	echo "Running the command : "
	echo "$cmd"
	echo
	$cmd

	if [ $? -eq 0 ]
	then
		echo "INFO: JKS files in Picketlink WAR and server.xml are same."
	else
		echo "ERROR: JKS files in Picketlink WAR and server.xml are different. Please update the correct JKS file in picketlink war"
	fi
fi


fi
echo

# web.xml
transportGuaranteeValue=`xmllint --xpath '/web-app/security-constraint/user-data-constraint/transport-guarantee/text()' $picketLinkWebXml`
printf  "%-50s %s \n" "transport-guarantee text in web.xml" ": $transportGuaranteeValue"
#
picketURL_wsdl=`grep 'soap12:address location'  $picketLinkStsWsdl |awk -F'"' '{print \$2}'`
printf "%-50s %s \n" "PicketlinkSTS URL in PicketLinkSTS.wsdl" ": $picketURL_wsdl"

defaultCfg="${pfsHome}/jboss-5.1.0.GA/server/default/conf/default.cfg"
getKeyValue "$defaultCfg" "picketlinkSTS.Webservice.endpointURI" " "
printf  "%-50s %s \n" "Picketlink URL in default.cfg" ": $value"

getKeyValue "$confProp" "sso.samlurl" " "
printf  "%-50s %s \n" "Picketlink URL in sso.war config.properties" ": $value"

getKeyValue "$pmfConfProp" "picketlinkurl" " "
printf  "%-50s %s \n" "Picketlink URL in PMFconfig.properties" ": $value"


### LDAP configurations

# usermanager.properties
echo
echo "Contents of conf/usermanager.properties:"
echo "----------------------------------------"
cat $usermanagerProps
echo "--------------------------------------------------------"

# sso.war
echo
echo "SSO Configurations:"
echo "-------------------"
echo


if [ ! -f $ssoWar ]
then
	echo
	echo "ERROR: sso.war is NOT FOUND at $ssoWar"
	echo
else

	echo
	echo "Configurations in sso.war :"
	echo "---------------------------"
### Unzip the sso.war

	
	getKeyValue "$confProp" "ldap.ip-address" " "
	printf "%-50s %s\n" "LDAP Address" ": $value"

	getKeyValue "$confProp" "ldap.port" " "
	printf "%-50s %s\n" "LDAP Port" ": $value"

	getKeyValue "$confProp" "ldap.usercontatiner" " "
	printf "%-50s %s\n" "LDAP User Container" ": $value"

	getKeyValue "$confProp" "ldap.domain" " "
	printf "%-50s %s\n" "LDAP Domain" ": $value"

	getKeyValue "$confProp" "ldap.admin" " "
	printf "%-50s %s\n" "LDAP Username" ": $value"

	getKeyValue "$confProp" "ldap.admin.passwd" " "
	printf "%-50s %s\n" "LDAP Password" ": $value"

	getKeyValue "$confProp" "portal.ip" " "
	printf "%-50s %s\n" "Portal Address (for redirection)" ": $value"

	getKeyValue "$confProp" "portal.port" " "
	printf "%-50s %s\n" "Portal Port (for redirection)" ": $value"

	getKeyValue "$confProp" "portal.ssolandingurl" " "
	printf "%-50s %s\n" "Portal SSO Landing URL (for login)" ": $value"

	getKeyValue "$confProp" "serverType" " "
	printf "%-50s %s\n" "Server Type (for PSC silent installer)" ": $value"

	getKeyValue "$confProp" "sso.hosted.server.for" " "
	printf "%-50s %s\n" "Producuct deployed (for login redirection)" ": $value"
fi


echo "=========================================================================================="
echo
echo "Database Configurations:"
echo "========================"

### OMS DB details 


if [ ! -f $adminPrefs ]
then
	echo
	echo "ERROR: admin.prefs NOT FOUND at $adminPrefs"
	echo
else
	echo
	echo "Contents of admin.prefs :"
	echo "-------------------------"
	cat $adminPrefs
fi

if [ ! -f $adminPrefs_conf ]
then
	echo
	echo "ERROR: admin.prefs NOT FOUND at $adminPrefs_conf"
	echo
else
	echo
	echo "Contents of conf/admin.prefs :"
	echo "------------------------------"
	cat $adminPrefs_conf
fi

### DB configurations from sso.war
echo
echo "DB Configurations in sso.war:"
echo "-----------------------------"

getKeyValue "$confProp" "enrolment.dbuser" " "
printf "%-50s %s\n" "DB Username" ": $value"

getKeyValue "$confProp" "enrolment.dbpassword" " "
printf "%-50s %s\n" "DB Password" ": $value"


### DB URLs from different places
echo
echo "DB URLs in configuration files :"
echo "--------------------------------"
getKeyValue "$confProp" "enrolment.dburl" " "
printf "%-50s %s\n" "DB URL in sso.war" ": $value"


getKeyValue "$usermanagerProps" "usermanager.jdbc.url" " "
printf "%-50s %s\n" "DB URL in usermanager.properties" ": $value"

echo "In server/default/conf/system.prefs :"
echo "-------------------------------------"
urls=`grep JSQLConnect $systemPrefs_conf | sed 's+<url>++g;s+</url>++g;s+\s*++g'`
for url in `echo $urls`
do
	printf "%50s %s \n" " " ": $url"
done

echo "In app/KYP/system.prefs :"
echo "-------------------------"
urls=`grep JSQLConnect $systemPrefs_app_KYP | sed 's+<url>++g;s+</url>++g;s+\s*++g'`
for url in `echo $urls`
do
	printf "%50s %s \n" " " ": $url"
done

echo "In app/system.prefs :"
echo "---------------------"
urls=`grep JSQLConnect $systemPrefs_app | sed 's+<url>++g;s+</url>++g;s+\s*++g'`
for url in `echo $urls`
do
	printf "%50s %s \n" " " ": $url"
done

echo "In oms/model/KYP.xml (model file) :"
echo "-----------------------------------"
urls=`grep JSQLConnect $modelXML | sed 's+.*url="++g;s+">++g'`
for url in `echo $urls`
do
	printf "%50s %s \n" " " ": $url"
done


echo "In datasource files :"
echo "---------------------"

### non-xa Data Sources
urls=`find ${pfsHome}/jboss-5.1.0.GA/server/default/deploy -name "*non-xa-ds.xml" | xargs -exec grep JSQLConnect |awk '{print \$2}' | sed 's+<connection-url>++g;s+</connection-url>++g;s+\s*++g'`
for url in `echo $urls`
do
	printf "%50s %s \n" " " ": $url"
done

### xa Data Sources
rm -f /tmp/${datestamp}/ds.tmp
for file in `find ${pfsHome}/jboss-5.1.0.GA/server/default/deploy -name "*-xa-ds.xml" 2>/dev/null| grep -v non-xa-ds`
do

### Class name needs to be captured separately
	jdbcClass=`grep xa-datasource-class $file | awk -F'>' '{print \$2}'|awk -F'<' '{print \$1}'`
	keys=`grep xa-datasource-property $file | awk -F'"' '{print $2}'`
        for key in $keys
	do
        	value=`grep xa-datasource-property $file | grep \"$key\" | awk -F'</' '{print $1}'  | awk -F'">' '{print $2}'`
	       	 if [ $key == "ServerName" ]
       		 then
       		         echo "${value}:1433"
	        else
       		         echo "$key=$value"
       		 fi
	done >>/tmp/${datestamp}/ds.tmp
	url=`awk -F'\n' '{if(NR == 1) {printf $0} else {printf "/"$0}}'  </tmp/${datestamp}/ds.tmp`
	printf "%50s %s \n" " " ": ${jdbcClass}://${url}"
	rm -f /tmp/${datestamp}/ds.tmp
done


echo
echo
echo "In PMFconfig.properties :"
echo "-------------------------"
getKeyValue "$pmfConfProp" "dbURL" " "
printf "%50s %s \n" " " ": $value"


echo "In quartz.properties:"
echo "---------------------"
getKeyValue "$quartzProps" "org.quartz.dataSource.quartzDataSource.URL" " "
printf "%50s %s \n" " " ": $value"


echo "=========================================================================================="
echo
echo "Data Source Connection Pool Sizes :"
echo "-----------------------------------"

        var=`find "${pfsHome}/jboss-5.1.0.GA/server/default/deploy" -name "*xa-ds.xml"`
        printf  "%-40s %-30s %-30s \n" "Data Source Name" "Minium Pool Size" "Maximum Pool Size";
        echo  "-----------------------------------------------------------------------------------------";
        echo
        for i in $var
        do
        JNDI=`egrep "jndi-name|pool-size"  $i | awk -F'<' '{print $2}'   |  sed -e 's+>+:+g' | awk -F':' '{print $2}'`
        printf "%-40s %-30s  %-30s \n"  $JNDI
        done
        echo





echo "=========================================================================================="
echo
echo "Document Viewer Configurations:"
echo "-------------------------------"

getKeyValue "$confProp" "docviewerURL" " "
printf "%-50s %s\n" "Document Viewer URL in sso.war" ": $value"

# DOCVIEWER_IP_ADDRESS in screening.properties

if [ ! -f $screeningProps ]
then
	echo
	echo "ERROR: screening.properties file NOT FOUND at $screeningProps"
	echo
else
	getKeyValue "$screeningProps" "DOCVIEWER_IP_ADDRESS" " "
	printf "%-50s %s\n" "Document Viewer IP in screening.properties" ": $value"
fi

prizmTmp="/tmp/${datestamp}/prizm"
unzip -qod $prizmTmp $prizmWar WEB-INF/web.xml
prizmWarWebXml="${prizmTmp}/WEB-INF/web.xml"


### Get the line number of WebServiceHost
lineNo=`grep -n WebServiceHost $prizmWarWebXml | awk -F':' '{print \$1}'`
totalLines=`wc -l $prizmWarWebXml | awk '{print \$1}'`
tailLines=`expr $totalLines - $lineNo`
value=`tail -$tailLines $prizmWarWebXml | grep param-value | head -1 | sed 's+<param-value>++g;s+</param-value>++g;s+\s*++g'`
printf "%-50s %s\n" "Document Viewer IP in Prizm war" ": $value"

### Prizm port : WebServicePort
lineNo=`grep -n WebServicePort $prizmWarWebXml | awk -F':' '{print \$1}'`
totalLines=`wc -l $prizmWarWebXml | awk '{print \$1}'`
tailLines=`expr $totalLines - $lineNo`
value=`tail -$tailLines $prizmWarWebXml | grep param-value | head -1 | sed 's+<param-value>++g;s+</param-value>++g;s+\s*++g'`
printf "%-50s %s\n" "Document Viewer Port in Prizm war" ": $value"

#documentviewer.webservice.host=192.168.4.194
#documentviewer.webservice.port=18681

if [ ! -f $docViewerCfg ]
then

	echo 
	echo "ERROR: documentviewer.cfg is NOT FOUND at $docViewerCfg"
	echo	
else
	getKeyValue "$docViewerCfg" "documentviewer.webservice.host" " "
	printf "%-50s %s\n" "Document Viewer IP in documentviewer.cfg" ": $value"
	
	getKeyValue "$docViewerCfg" "documentviewer.webservice.port" " "
	printf "%-50s %s\n" "Document Viewer Port in documentviewer.cfg" ": $value"
fi

echo "=========================================================================================="
echo
echo "Configurations in screening.properties:"
echo "---------------------------------------"

#KeyStoreName=newstore.ks
#TrustStoreName=newtrust.ks
#CerificatePassword=akchincertificate
#ThomsonRootUrl=https://a325.wgs.thomson.com/api/v1
#IS_THOMSON_REQUEST_REQUIRED=true
#THOMSON_REQUEST_THRU_BROKER=false
#THOMSON_REQUEST_BROKER_SERVER=dhi-dev1
#THOMSON_REQUEST_BROKER_PORT=6666



if [ ! -f $screeningProps ]
then	
	echo
	echo "ERROR: screening.properties file NOT FOUND at $screeningProps"
	echo	
else
	getKeyValue "$screeningProps" "KeyStoreName" " "
	printf "%-50s %s \n" "KeyStore Name" ": $value"

	getKeyValue "$screeningProps" "TrustStoreName" " "
	printf "%-50s %s \n" "TrustStore Name" ": $value"
	screeningTrustStore=$value

	getKeyValue "$screeningProps" "CerificatePassword" " "
	printf "%-50s %s \n" "Store Password" ": $value"
	screeningTrustStorePassword=$value

	getKeyValue "$screeningProps" "ThomsonRootUrl" " "
	printf "%-50s %s \n" "TR URL" ": $value"

	getKeyValue "$screeningProps" "IS_THOMSON_REQUEST_REQUIRED" " "
	printf "%-50s %s \n" "TR Flag" ": $value"

	getKeyValue "$screeningProps" "THOMSON_REQUEST_THRU_BROKER" " "
	printf "%-50s %s \n" "TR Broker Flag" ": $value"

	getKeyValue "$screeningProps" "THOMSON_REQUEST_BROKER_SERVER" " "
	printf "%-50s %s \n" "TR Broker Server Name" ": $value"

	getKeyValue "$screeningProps" "THOMSON_REQUEST_BROKER_PORT" " "
	printf "%-50s %s \n" "TR Broker Server Port" ": $value"

#### Verify that PFS Key is imported and available in TrustStore used in screening.properties
### Check whether the certificate is imported in cacerts
	if [ -r ${pfsHome}/jboss-5.1.0.GA/server/default/conf/${screeningTrustStore} ]
	then
	cert=`${pfsHome}/jdk1.6.0_17/bin/keytool  -list -keystore ${identityJks} -storepass password | grep 'Certificate fingerprint'`

	${pfsHome}/jdk1.6.0_17/bin/keytool  -list -keystore ${pfsHome}/jboss-5.1.0.GA/server/default/conf/${screeningTrustStore} -storepass ${screeningTrustStorePassword} | grep "$cert" >/dev/null 2>&1

	echo
	if [ $? -eq 0 ]
	then
       		echo "INFO: PFS certificate is imported in the Trust Store ${screeningTrustStore} used by screeing.properties"
	else
       		echo "ERROR: PFS certificate is NOT imported in the Trust Store ${screeningTrustStore} used by screening.properties"
	fi
	echo
	echo "List of Trusted Certificates in the Trust Store ${screeningTrustStore}:"
	echo "-----------------------------------------------------------------------"

	${pfsHome}/jdk1.6.0_17/bin/keytool  -list -keystore ${pfsHome}/jboss-5.1.0.GA/server/default/conf/${screeningTrustStore} -storepass ${screeningTrustStorePassword}
	else
	
		echo
		echo "ERROR: Trust Store ${screeningTrustStore} used by screening.properties is NOT FOUND at ${pfsHome}/jboss-5.1.0.GA/server/default/conf"
		echo
	fi

fi
echo


echo "=========================================================================================="
echo
echo "Configurations in PMFconfig.properties:"
echo "---------------------------------------"

#systemName=192.168.4.209
#systemPort=8080
#picketlinkurl=http://192.168.4.209:8080/picketlink-sts-1.0.0/PicketLinkSTS
#isLinuxEnvironment=false
#dbURL=jdbc:JSQLConnect://192.168.4.240:1433/databaseName=KYPENROLLMENTOMS/selectMethod=Cursor

if [ ! -f $pmfConfProp ]
then	
	echo
	echo "ERROR: PMFconfig.properties file NOT FOUND at $pmfConfProp"
	echo	
else
	
	getKeyValue "$pmfConfProp" "systemName" " "
	printf "%-50s %s \n" "System Name" ": $value"

	getKeyValue "$pmfConfProp" "systemPort" " "
	printf "%-50s %s \n" "System Port" ": $value"

	getKeyValue "$pmfConfProp" "isLinuxEnvironment" " "
	printf "%-50s %s \n" "isLinuxEnvironment Flag" ": $value"

fi

echo "=========================================================================================="
echo
echo "Configurations in AccountHistoryApp.war:"
echo "----------------------------------------"

if [ ! -r "${accHistAppWar}" ]
then
        echo
        echo "ERROR: Unable to read AccountHistoryApp.war at ${accHistAppWar}"
        echo
else

	tempDir="/tmp/${datestamp}/AccountHistoryWar"
	unzip -qod $tempDir $accHistAppWar WEB-INF/classes/AWSCredentials.properties

#accessKey=AKIAIU3C44QELASU4BHA
#secretKey=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
#dynamoDbEndPoint=https://dynamodb.us-west-2.amazonaws.com
#Region=US_WEST_2

	awsCredPropFile="${tempDir}/WEB-INF/classes/AWSCredentials.properties"

	getKeyValue "$awsCredPropFile" "accessKey" " "
	printf "%-50s %s \n" "AWS Access Key" ": $value"

	getKeyValue "$awsCredPropFile" "secretKey" " "
	printf "%-50s %s \n" "AWS Secret Key" ": $value"

	getKeyValue "$awsCredPropFile" "dynamoDbEndPoint" " "
	printf "%-50s %s \n" "DynamoDB End-point" ": $value"

	getKeyValue "$awsCredPropFile" "Region" " "
	printf "%-50s %s \n" "AWS Region" ": $value"

fi

echo "=========================================================================================="
echo
echo "Configurations in AccountHistoryProcess.jar:"
echo "--------------------------------------------"


if [ ! -r "${accHistJar}" ]
then
        echo
        echo "ERROR: Unable to read AccountHistoryProcess.jar at ${accHistJar}"
        echo
else

	tempDir="/tmp/${datestamp}/AccountHistoryJar"

	unzip -qod $tempDir $accHistJar hibernate.cfg.xml portal.cfg.xml AWSCredentials.properties

	awsCredPropFile="${tempDir}/AWSCredentials.properties"

	getKeyValue "$awsCredPropFile" "accessKey" " "
	printf "%-50s %s \n" "AWS Access Key" ": $value"

	getKeyValue "$awsCredPropFile" "secretKey" " "
	printf "%-50s %s \n" "AWS Secret Key" ": $value"

	getKeyValue "$awsCredPropFile" "dynamoDbEndPoint" " "
	printf "%-50s %s \n" "DynamoDB End-point" ": $value"

	getKeyValue "$awsCredPropFile" "Region" " "
	printf "%-50s %s \n" "AWS Region" ": $value"

### connection.url
	value=`grep connection.url ${tempDir}/hibernate.cfg.xml | awk -F'>' '{print $2}' | awk -F'<' '{print $1}'`
	printf "%-50s %s \n" "DB Connection URL in hibernate.cfg.xml" ": $value"

	value=`grep connection.url ${tempDir}/portal.cfg.xml | awk -F'>' '{print $2}' | awk -F'<' '{print $1}'`
	printf "%-50s %s \n" "DB Connection URL in portal.cfg.xml" ": $value"

fi


echo "=========================================================================================="
echo
echo "Configurations in CaseSummary.war:"
echo "----------------------------------"


if [ ! -r "${caseSummaryWar}" ]
then
        echo
        echo "ERROR: Unable to read CaseSummary.war at ${caseSummaryWar}"
        echo
else

### Let us update the JAR now
	tempDir="/tmp/${datestamp}/CaseSummary"

	unzip -qod $tempDir $caseSummaryWar WEB-INF/classes/jdbc.properties

	jdbcPropFile="${tempDir}/WEB-INF/classes/jdbc.properties"

	value=`grep jdbc.url ${tempDir}/WEB-INF/classes/jdbc.properties | awk '{print $2}'`
	printf "%-50s %s \n" "JDBC URL for Enrollment" ": $value"

	value=`grep jdbc.portalUrl ${tempDir}/WEB-INF/classes/jdbc.properties | awk '{print $2}'`
	printf "%-50s %s \n" "JDBC URL for Portal" ": $value"

fi

echo "=========================================================================================="
echo
echo "DMS Configurations:"
echo "==================="

if [ ! -r $dmsConfProp ]
then
	echo
	echo "ERROR: Unable to read DMS properties file at @dmsConfProp"
	echo
else

	getKeyValue "$dmsConfProp" "RestEnabled" " "
	printf "%-50s %s \n" "Rest API Flag (used for Wildfly)" ": $value"

### DMS_URL Values from model file
	echo
	printf "%-50s " "DMS_URL Values in the Model" 
	firstLine="true"
	for url in `grep DMS_URL $modelXML | grep -v rmi|awk -F'"' '{print $4}'`
	do
		if [ $firstLine == "true" ] 
		then
			printf "%s \n" ": $url"
			firstLine="false"
		else
			printf "%52s %s \n" " " "$url"
		fi
	done


fi


echo "=========================================================================================="
echo
echo "Cluster Configurations:"
echo "======================="

### EHCACHE Flag

getKeyValue "$defaultCfg" "Cache.ENABLE_EH_CACHE" " "
ehcacheFlag=$value

printf "%-50s %s \n" "EHCACHE Flag in default.cfg" ": $ehcacheFlag"
echo

echo "Contents of ehcache.xml:"
echo "------------------------"

if [ -r "${pfsHome}/jboss-5.1.0.GA/server/default/conf/ehcache.xml" ]
then
	cat ${pfsHome}/jboss-5.1.0.GA/server/default/conf/ehcache.xml
else
	echo "ERROR: Unable to read ehcache.xml at ${pfsHome}/jboss-5.1.0.GA/server/default/conf/ehcache.xml" 
	echo
fi

echo
echo "--------------------------------------------------------------------------"


echo
#      <attribute name="ControlChannelName">jbm-control</attribute>
#      <attribute name="DataChannelName">jbm-data</attribute>


jmsFile="${pfsHome}/jboss-5.1.0.GA/server/default/deploy/messaging/mssql-persistence-service.xml"
jmsFileNoComments="/tmp/${datestamp}/mssql-persistence-service.xml"

if [ ! -f $jmsFile ]
then
	echo "ERROR: JMS Persistence file is NOT FOUND at $jmsFile"
	echo
else
### Remove the comments from XML
	cat $jmsFile | sed '/<!--.*-->/d' | sed '/<!--/,/-->/d' > $jmsFileNoComments
	controlChannelName=`grep ControlChannelName $jmsFileNoComments `
	dataChannelName=`grep DataChannelName $jmsFileNoComments `
	
	echo "Configurations in  mssql-persistence-service.xml:"
	echo "-------------------------------------------------"
	echo $controlChannelName
	echo $dataChannelName
	echo
	
fi





### Remove the tmp folder
#rm -rf /tmp/${datestamp}


#
### END
#
endTime


### Now exit gracefully
exit 0
