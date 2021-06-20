#!/bin/bash

echo "######## Starting enviroment ########"
echo ""
echo "n1 ---- CH1 ---- n2 ---- CH3 ---- n5"
echo "|  \          /  |  \          /  |"
echo "CH1   CH1|CH2    CH2   CH2|CH3    CH3"
echo "|  /          \  |  /          \  |"
echo "n3 ---- CH2 ---- n4 ---- CH3 ---- n6"
echo "|  \          /  |  \          /  |"
echo "CH4   CH4|CH5    CH5   CH5|CH6    CH6"
echo "|  /          \  |  /          \  |"
echo "n7 ---- CH4 ---- n8 ---- CH6 ---- n9"
echo ""

# n1
/Applications/love.app/Contents/MacOS/love src CH1,CH2 &

sleep 3

# n2
/Applications/love.app/Contents/MacOS/love src CH1,CH2,CH3 &

sleep 3

# n3
/Applications/love.app/Contents/MacOS/love src CH1,CH2,CH4 &

sleep 3

# n4
/Applications/love.app/Contents/MacOS/love src CH1,CH2,CH3,CH5 &

sleep 3

# n5
/Applications/love.app/Contents/MacOS/love src CH2,CH3 &

sleep 3

# n6
/Applications/love.app/Contents/MacOS/love src CH2,CH3,CH6 &

sleep 3

# n7
/Applications/love.app/Contents/MacOS/love src CH4,CH5 &

sleep 3

# n8
/Applications/love.app/Contents/MacOS/love src CH4,CH5,CH6 &

sleep 3

# n9
/Applications/love.app/Contents/MacOS/love src CH5,CH6