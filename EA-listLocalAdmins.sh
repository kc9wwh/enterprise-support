#!/usr/bin/env zsh

users=$(dscl . -read /Groups/admin GroupMembership | sed 's/GroupMembership\:\ //')

for user in ${users[*]}; do
    echo "<result>$user</result>"
done