#!/bin/bash

########################################################
# by serdeliuk feb 2021
# extract xbl.elf or a dump from xbl partition to efi folder and files to be added to EDK2 port in binary folder
# also create fdf sections and add UUIDs files in each driver folder.
#
########################################################

DEVICE="RedmiNote7Pkg"


if ! [ -x "$(command -v 7z)" ]; then
  echo 'Error: 7z is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v uefi-firmware-parser)" ]; then
  echo 'Error: uefi-firmware-parser is not installed.' >&2
  exit 1
fi

if ls xbl 1> /dev/null 2>&1; then
	echo "xbl folder already exists please remove or rename the folder"
	exit 1
    else
	if ls xbl.elf 1> /dev/null 2>&1; then
		echo "Extractig xbl.elf"
		7z x xbl.elf -r -o./xbl > /dev/null 2>&1

		echo "Extractig volumes from xbl"
		7z x ./xbl/16 -r -o./xbl/uefi_fv > /dev/null 2>&1

		echo -ne "Extractig files\n\n"
		uefi-firmware-parser -e -b -o ./xbl/fv_extracted ./xbl/uefi_fv/16~ > /dev/null 2>&1
	    else
		echo "xbl.elf file not found, place xbl.elf in the same folder with the extractor..."
		exit 2
	fi
fi

base="0.extracted"
folders=`ls -1d xbl/fv_extracted/volume-8/*/ | grep -v fffffff`

for folder in $folders
    do
	if ls $folder*.ui 1> /dev/null 2>&1; then
	    name=`cat $folder*.ui | tr -d '\0'`
	    if [ -z $name ]; then
		continue
	    else
		if ls $folder*.depex 1> /dev/null 2>&1; then
		    echo "Creating: $name"
		    mkdir -p $base/$name
		    basename $folder > $base/$name/uuid.txt
		    cp -rf $folder/section0.dxe.depex $base/$name/$name.depex
		    cp -rf $folder/section1.pe $base/$name/$name.efi
		    uuid=`basename $folder | awk -Ffile- {'print $2'}`
		    echo -ne "\n  FILE DRIVER = $uuid { \n\t SECTION DXE_DEPEX = $DEVICE/Binary/$name/$name.depex \n\t SECTION PE32 = $DEVICE/Binary/$name/$name.efi \n\t SECTION UI = \"$name\" \n  }\n" >> $base/gen_config.fdf
		else
		    if ls $folder*.pe 1> /dev/null 2>&1; then
			echo "Creating: $name"
			mkdir -p $base/$name
			basename $folder > $base/$name/uuid.txt
			uuid=`basename $folder | awk -Ffile- {'print $2'}`
			echo -ne "\n  FILE DRIVER = $uuid { \n\t SECTION PE32 = $DEVICE/Binary/$name/$name.efi \n\t SECTION UI = \"$name\" \n  }\n" >> $base/gen_config.fdf
			if ls $folder/section0.pe 1> /dev/null 2>&1; then
			    cp -rf $folder/section0.pe $base/$name/$name.efi
			else
			    cp -rf $folder/section1.pe $base/$name/$name.efi
			fi
		    else
			uuid=`basename $folder`
			cp -rf $folder/section1.raw $base/$uuid-$name
		    fi
		fi
	    fi
	else
	    continue
	fi
done
