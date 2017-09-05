#!/bin/bash

# This script copies the application bundle to the publication directory.
# It will by the ABS on publishing a build.

# The script can be run manually from the root of the applicaiton repository
# as follows:

# Usage make-app-pub.sh AppDest AppPath AppName AppRev AppType
#   where:
#   AppDest       = Path to the publication destination directory.
#   AppName       = Base name of the application eg: APL-MTR-A01-1.0.
#   AppRev 	      = Revision number for this build.
#   AppBuildType  = Build type TLA (eg 'STB', 'STG').

# Bundle name to be published will be of the form:
#   APL-MTR-A01-1.0.X-TLA.fap where X is the build revision number and 'TLA'
#   is the build type.

AppDest=$1
AppName=$2
AppRev=$3
AppType=$4

APPSRC="./tmp/"$AppName"."$AppRev"-"$AppType".fap"

if [ $AppType = "STB" ]; then
	APPDST=$AppDest"/Stable"
elif [ $AppType = "STG" ]; then
	APPDST=$AppDest"/Staging"
else
	echo "Invalid build type - must be one of STB, STG ......"
	return
fi

echo $APPSRC
echo $APPDST

cp $APPSRC $APPDST

