#!/bin/sh
for f in `find ../kubernetes_original/ -type f -iname "*.y*ml"`
#for f in `find ../kubernetes_original/test/kubemark/resources/ -type f -iname "*.y*ml"`
do
	ls -l "$f"
	./yaml_comments.rb "$f"
	rc=$?
	if [ $rc -ne 0 ]
	then
		echo "Failed on YAML: '$f'"
		#exit 1
	fi
done
