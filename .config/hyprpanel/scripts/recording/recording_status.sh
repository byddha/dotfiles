#!/bin/bash

if pgrep wf-recorder > /dev/null; then
    echo '{"alt": "recording"}'
else
    echo ""
fi
