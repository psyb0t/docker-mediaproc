#!/bin/bash
# Update font cache if extra fonts mounted
if [ -d "/usr/share/fonts/custom" ] && [ "$(ls -A /usr/share/fonts/custom 2>/dev/null)" ]; then
    echo "Updating font cache with custom fonts..."
    fc-cache -f /usr/share/fonts/custom
fi
