#!/bin/bash

DEBUG=${1:-"false"}

SCRIPT='/home/test/scripts/Measurement_parsing.py'
PYTHON='/usr/bin/python'
RSYNCUSER='test'

DATA_ARCHIVE="/home/$RSYNCUSER/Data_Archive"

[[ ! -d $DATA_ARCHIVE ]] && mkdir $DATA_ARCHIVE

for Measurement_DIR in $(find /home/$RSYNCUSER -name Measurements); do

	for MEAS_SUBDIR in $(ls $Measurement_DIR); do
		[[ $DEBUG == "true" ]] && echo $MEAS_SUBDIR
		for FILE in $(ls $Measurement_DIR/$MEAS_SUBDIR); do
			$PYTHON $SCRIPT $Measurement_DIR/$MEAS_SUBDIR/$FILE 
			sleep 0.1
		done
	done

	rsync -avz --remove-source-files $Measurement_DIR $DATA_ARCHIVE
done
