#!/bin/bash

sleep 25
thunderbird & sleep 17 && kdocker -b -w `wmctrl -l | grep -i thunderbird | awk '{print $1}'`
