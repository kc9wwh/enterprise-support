#!/usr/bin/env zsh

# EA for Jamf Pro to see if the process jamfHelper is actively running on computers.
# EA returns 'True' if running, 'False' if not.

result=$(pgrep -q jamfHelper && echo "True" || echo "False")
echo "<result>$result</result>"

exit 0