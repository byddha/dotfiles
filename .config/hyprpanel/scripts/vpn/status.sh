#!/bin/bash
FORTI_CONNECTED=false
MULLVAD_CONNECTED=false

if pgrep openfortivpn >/dev/null; then
  FORTI_CONNECTED=true
fi

if mullvad status 2>/dev/null | grep -q "Connected"; then
  MULLVAD_CONNECTED=true
fi

if [ "$FORTI_CONNECTED" = true ] && [ "$MULLVAD_CONNECTED" = true ]; then
  echo '{"alt": "both", "tooltip": "FortiVPN and Mullvad connected", "status": "active", "display": "Forti + Mullvad VPN", "details": "All VPNs active"}'
elif [ "$FORTI_CONNECTED" = true ]; then
  echo '{"alt": "fortivpn", "tooltip": "FortiVPN connected", "status": "partial", "display": "FortiVPN", "details": "FortiVPN connected"}'
elif [ "$MULLVAD_CONNECTED" = true ]; then
  echo '{"alt": "mullvad", "tooltip": "Mullvad connected", "status": "partial", "display": "MullvadVPN", "details": "Mullvad connected"}'
else
  echo '{"alt": "none", "tooltip": "No VPN connected", "status": "inactive", "display": "No VPN", "details": "VPN is disconnected"}'
fi
