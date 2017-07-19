#!/bin/sh
cat > input
/home/justa/dev/rtokenize/rtokenize.rb -$1 < input > output
rc=$?
if [ $rc -ne 0 ]
then
	cat input
	exit 0
fi
/home/justa/dev/rtokenize/rlocalize.rb $1 output input
rc=$?
if [ $rc -ne 0 ]
then
	cat input
	exit 0
fi
cat output
