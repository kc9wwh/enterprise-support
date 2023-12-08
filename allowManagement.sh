#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2023 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script was designed to be used in the event of a macOS enrollment not coming into
# Jamf Pro as "Managed". This script will automate the checking of the box "Allow Jamf
# Pro to perform management tasks" of the computer inventory record. 
#
# REQUIREMENTS:
#		- Jamf Pro 10.49 or later
#		- macOS Clients running version 11.xx or later (tested on macOS Sonoma)
#
# API PRIVILEGES:
#		- Update - Computers
#		- Update - Users
#		- Read - Computers
# 
# https://jamf.it/classic-api-privilege-requirements
# https://jamf.it/jpro-api-privilege-requirements
#
# 
# Written by: Joshua Roskos | Jamf
#
#
# Revision History
# 2020-12-07: Initial release
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## User Variables
jamfProURL="$4"
jamfClientID="$5"
jamfClientSecret="$6"

## System Functions
getAccessToken() {
	response=$(curl --silent --location --request POST "${jamfProURL}/api/oauth/token" \
 	 	--header "Content-Type: application/x-www-form-urlencoded" \
 		--data-urlencode "client_id=${jamfClientID}" \
 		--data-urlencode "grant_type=client_credentials" \
 		--data-urlencode "client_secret=${jamfClientSecret}")
 	access_token=$(echo "$response" | plutil -extract access_token raw -)
 	token_expires_in=$(echo "$response" | plutil -extract expires_in raw -)
 	token_expiration_epoch=$(($current_epoch + $token_expires_in - 1))
}

checkTokenExpiration() {
 	current_epoch=$(date +%s)
    if [[ token_expiration_epoch -ge current_epoch ]]; then
        echo "Token valid until the following epoch time: " "$token_expiration_epoch"
    else
        echo "No valid token available, getting new token"
        getAccessToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${access_token}" $jamfProURL/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]; then
		echo "Token successfully invalidated"
		access_token=""
		token_expiration_epoch="0"
	elif [[ ${responseCode} == 401 ]]; then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}

getJamfProCompID() {
    mySerial=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
    osMajor=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
    if [[ "$osMajor" -ge 11 ]]; then
	    checkTokenExpiration
	    jamfProID=$(curl -k -H "Authorization: Bearer $access_token" $jamfProURL/JSSResource/computers/serialnumber/$mySerial/subset/general | xpath -e "//computer/general/id/text()")
    else
        echo "Unsupported version of macOS. Exiting."
		invalidateToken
        exit 10 # Return an error code of 10 when version of macOS is unsupported.
    fi
}

## Start Script

xmlPayload="<computer><general><remote_management><managed>true</managed></remote_management></general></computer>"

checkTokenExpiration
getJamfProCompID
checkTokenExpiration
remoteManagement=$(curl -s -H "Authorization: Bearer ${access_token}" $jamfProURL/JSSResource/computers/id/$jamfProID -X GET | xpath -e "//computer/general/remote_management/managed/text()")
if [[ $remoteManagement == "true" ]]; then 
	echo "$mySerial: Remote Managment Already Enabled."
	exit 0
else
	checkTokenExpiration
	responseCode=$(curl -w "%{http_code}" -H "Content-Type: application/xml" -H "Accept: application/xml" -H "Authorization: Bearer ${access_token}" $jamfProURL/JSSResource/computers/id/$jamfProID -X PUT -d "$xmlPayload" -s -o /dev/null)
	if [[ ${responseCode} == 201 ]]; then
		echo "$mySerial: Remote Management Successfully Enabled"
		invalidateToken
		exit 0
	else
		echo "Unkown Error - code: $responseCode"
		invalidateToken
		exit 99 # Unknown error occured
	fi
fi