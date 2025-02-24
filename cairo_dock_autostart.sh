#!/bin/bash
# Check if cairo-dock is running and kill it if it is
if pgrep cairo-dock > /dev/null
then
	killall cairo-dock
fi

sleep 15
cairo-dock
