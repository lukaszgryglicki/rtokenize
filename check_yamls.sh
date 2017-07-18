#!/bin/sh
for f in `find ../kubernetes_original/ -type f -iname "*.y*ml"`
do
	res=`./rtokenize.rb -y < $f > out`
	rc=$?
	if [ $rc -ne 0 ]
	then
		echo "$f ==> $rc"
	fi
done
