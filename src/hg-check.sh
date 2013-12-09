#!/bin/bash
for file in */ .*/ ;
do 
	#echo "$file";
	# Ignore current and parent directory
	if [ "$file" == "./" ] || [ "$file" == "../" ]; then
		continue;
	fi
	cd "$file";
	RESULT=$(hg --config ui.report_untrusted=False id | grep "+");
	if [ "$RESULT" != "" ]; then
		echo "$file has uncommited changes.";
	fi
	cd ..;
done

