#!/bin/bash

taildrop_folder="${TAILDROP_FOLDER:-$HOME/Downloads}"

mv_safe() {
    src="$1"
    dest_dir="$2"

    # Extract filename and extension from the source file
    filename=$(basename -- "$src")
    basename="${filename%.*}"
    ext="${filename##*.}"
    new_filename="$filename"

    # Ensure the destination directory exists
    mkdir -p "$dest_dir"

    # Check if the file exists and find a unique name
    i=1
    while [[ -e "$dest_dir/$new_filename" ]]; do
        new_filename="${basename}($i).${ext}"
        ((i++))
    done

    # Move the file
    mv "$src" "$dest_dir/$new_filename"

    # Return the final filename
    echo "$new_filename"
}

while :
do
	res=-1;
	tempfolder="/tmp/taildroptemp_$(date +"%T.%N")";
	mkdir $tempfolder;
	tailscale file get $tempfolder;
	if [[ $? -eq 1 ]]; then
		sleep 10;
		continue;
	fi
	filename=`ls $tempfolder`;
	if [[ ! -e "$filename" ]]; then
		continue;
	fi
	tempfilepath=$tempfolder/$filename;
	newname=$(mv_safe "$tempfilepath" "$taildrop_folder");
	rmdir $tempfolder;
	filepath=$taildrop_folder/$newname;
	read res < <(notify-send -a "Tailscale" -t 5000 -A "OK" -A "Open" -A "Delete" "File \"$newname\" Received" "Saved to <a href='file://$taildrop_folder'>${taildrop_folder#$HOME/}</a>");
	if [ $res -eq 1 ]; then #if user selected OPEN, open in default app
		xdg-open $filepath;
	elif [ $res -eq 2 ]; then #if user selected DELETE, delete file and notify
		rm $filepath;
		notify-send -a "System" -t 1000 "File Deleted"
	fi
done
