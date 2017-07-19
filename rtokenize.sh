#!/bin/sh
./rtokenize.rb -$1 < "$2" > out.token
rc=$?
if [ $rc -ne 0 ]
then
	cat "$2"
fi
./rlocalize.rb $1 out.token "$2"
rc=$?
if [ $rc -ne 0 ]
then
	cat "$2"
fi
cat out.token
