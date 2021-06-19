#!/bin/bash

echo "######## Starting enviroment ########"
echo ""
echo "n1 ---- CH1 ---- n2 ---- CH3 ---- n5"
echo "|  \          /  |                |"
echo "CH1   CH1|CH2    CH2              CH3"
echo "|  /          \  |                |"
echo "n3 ---- CH2 ---- n4               n6"
echo ""

# n1
/Applications/love.app/Contents/MacOS/love src CH1 &

sleep 3

# n2
/Applications/love.app/Contents/MacOS/love src CH1,CH2,CH3 &

sleep 3

# n3
/Applications/love.app/Contents/MacOS/love src CH2 &

sleep 3

# n4
/Applications/love.app/Contents/MacOS/love src CH1,CH2 &

sleep 3

# n5
/Applications/love.app/Contents/MacOS/love src CH3 &

sleep 3

# n6
/Applications/love.app/Contents/MacOS/love src CH3