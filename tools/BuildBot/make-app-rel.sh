#!/bin/bash

# Note that script should be run from the root of the repository. i.e. FMEApps.

# Usage:
#   This script is normally run by the build system but it can also be run
#   manually as follows:

# 
# ./tools/BuildBot/make-app-rel.sh AppName AppBranchId AppBuildNo AppBuildType
#   where:
#   AppName     = Base name of the created bundle (eg: APL-MTR-A01)
#   AppBranchId = 2 Digit branch ID of the form 1.0 (if run by hand, this can be anything)
#   AppBuildNo  = Decimal buildnumber for this build
#   AppBuildType= A three letter TLA for the type of build. Currently supported
#                 build types are STB (stable), STG (staging) & DEV (internal
#                 development build only).

# The EID for the application will be constructed in the form 01:00:AA:BB:WX:YZ
#   where:
#   01:00   Is a constant prefix for all applets
#   AA:BB   Is the hex representation of the AppBranchId above. (e.g. 01:00)
#   WX:YZ   Is the 16bit hex representation of the build number. (e.g. 00:1A for build 26)
#
# Example:
# 
# FMEApps>./tools/BuildBot/make-app-rel.sh APL-LMT-HOL01 1.0 15 STG
# 
# Will create a bundle from the source tree placing it in the FMEApps/tmp directory,
# with the name APL-LMT-HOL01-STG.fap
# The generated EID will be 01:00:01:00:00:0F

AppName=$1
AppBranchId=$2
AppBuildNo=$3
AppBuildType=$4

# Hex byte representation of the version number used to construct the
# EntitiyId. Some sed magic (provided by Dave) is used to format the
# branch id and build numbers.

# This magic converts "2.1" to "02.01" with range checking etc.
APPBRANCHID=$(echo $AppBranchId | sed -n -e 's/\([0-9]\+\)/@0000\1@/g' -e 's/@0*\([^@]\{2,\}\)@/\1/g' -e p)

# This magic converts the decimal build number to hex form AA.BB
# and appends it to the branch Id part from above.
APPVER=$APPBRANCHID$( printf "%04lx\n" $AppBuildNo | sed -n 's/\(..\)/.\1/gp' )

# Human readable string of the form A.B.C where A.B is the branch Id
# and C is the decimal build number. This is used for file names and
# paths in the published package.
APPVERSTR=$AppBranchId"."$AppBuildNo

# The entitiy ID is constructed by appending the hex version ID to the
# EID prefix field.

# The entity ID prefix field is determined by the AppBuildType parameter.
if [ ${AppBuildType} == "DEV" ] ; then
    EIDPref="00:00:"
elif [  ${AppBuildType} == "STG" ] ; then
    EIDPref="00:01:"
elif [  ${AppBuildType} == "STB" ] ; then
    EIDPref="00:02:"
else
    # Unknown type
    EIDPref="ff:ff:"
fi

APPEID=${APPVER//./:}
EID=${EIDPref}${APPEID}

# Construct the applet name.
APPNAME=$AppName"-"${APPVERSTR}"-"${AppBuildType}

# The final parameters.
echo $APPVER
echo $APPVERSTR
echo $EID
echo $APPNAME

# construct the bundle in the tmp working directory.
# remove any previously created directory
if [ -e ./tmp/${APPNAME} ]; then
    rm -rf  ${prefix}tmp/${APPNAME}
    rm -rf  ${prefix}tmp/${APPNAME}.fap
fi

mkdir -p ./tmp/${APPNAME}
mkdir -p ./tmp/${APPNAME}/src
mkdir -p ./tmp/${APPNAME}/lib
mkdir -p ./tmp/${APPNAME}/lib/dkjson
mkdir -p ./tmp/${APPNAME}/lib/fs-utils
mkdir -p ./tmp/${APPNAME}/lib/devicemgr
# Build up the runtime directory structure in ./tmp
cp ./Applets/messages.fem   			./tmp/${APPNAME}
cp ./Applets/fap.xml        			./tmp/${APPNAME}
cp -rf ./Applets/src/*.lua      		./tmp/${APPNAME}/src
cp -rf ./Applets/lib/*.lua      		./tmp/${APPNAME}/lib
cp -rf ./Applets/lib/dkjson/*.lua   	./tmp/${APPNAME}/lib/dkjson
cp -rf ./Applets/lib/devicemgr/*.lua 	./tmp/${APPNAME}/lib/devicemgr
cp -rf ./Applets/lib/fs-utils/*.lua 	./tmp/${APPNAME}/lib/fs-utils
cd ./tmp

# Patch the version information into the appropriate files
# replacing the placeholder names.

# Fix the EID in messages.fem
sed -i 's/BuildNumPH/'${EID}'/g' ${APPNAME}/messages.fem

# Fix the AppletName in messages.fem
sed -i 's/AppletNamePH/'${APPNAME}'/g' ${APPNAME}/messages.fem

# Fix the AppletName in fap.xml
sed -i 's/AppletNamePH/'${APPNAME}'/g' ${APPNAME}/fap.xml

# Fix the AppletVersion in defines.lua
sed -i 's/AppletVersionPH/'${APPVERSTR}'/g' ${APPNAME}/src/defines.lua

# Create the tar file which represents the bundle.
tar cvf ${APPNAME}.fap ${APPNAME} --exclude='*~' --exclude='*.bak'
cd ..

