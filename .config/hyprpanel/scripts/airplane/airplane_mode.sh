#!/bin/bash

all_blocked=$(rfkill -J | jq -r '.rfkilldevices | map(.soft == "blocked") | all')

if [ "$all_blocked" = "true" ]; then
    echo '{"alt": "airplane"}'
else
    echo ""
fi
