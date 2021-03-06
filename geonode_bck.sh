#!/bin/bash
# geonode backupper
echo "*****************************************************************"
echo "-----------------------------------------------------------------"
echo "*****************************************************************"

echo
echo $(date) "--> starting bck for geonode dbs"

sudo mount /dev/xvdg /mnt/auto_bck

today_dir=/mnt/auto_bck/pg_dumps/$(date +"%Y%m%d")_dump
echo "creating backup folder -->" $today_dir
mkdir $today_dir

echo $(date) "--> dumping geonode db"
pg_dump -Fc -U geonode geonode > $today_dir/geonode.dump
echo $(date) "--> geonode db dumped"

echo $(date) "--> dumping geonode_imports db"
pg_dump -Fc -b -U geonode geonode_imports > $today_dir/geonode_imports.dump
echo $(date) "--> geonode_imports db dumped"

# removing old folders
bck_dir=/mnt/auto_bck/pg_dumps

# get current month
cur_m=$(date +%m)
# get previous month
prev_m=$(expr $cur_m - 1)
# get previous month with leading 0
prev_m2=$(printf "%02d" $prev_m)
# build re that matches current and previous month backups
re=$(echo "201[6-9]("$cur_m"|"$prev_m2")")
# loop on backups in days other than 01, 08, 15, 23
for dir in $(ls $bck_dir | head -n -7 | grep -E $re | grep -Ev \
'(01|08|15|23)_dump')
do
 echo removing $dir
 rm -r $(echo $bck_dir"/"$dir)
done

echo "end of dumping procedure"

echo "-----------------------------------------------------------------"
echo $(date) "--> starting bck for geoserver data folder"

this_week_dir=/mnt/auto_bck/geoserver_bck/$(date +"%Yweek%W")
echo "checking backup folder -->" $this_week_dir

if [ -e $this_week_dir ]
then
  echo folder exists
  echo $(date) "--> creating incremental archive"
  sudo tar -cpzf $this_week_dir/incr_dump.tgz -C /mnt -g $this_week_dir/tarlog.snap --backup=numbered geoserver_data
  sudo cp $this_week_dir/tarlog_lev0.snap $this_week_dir/tarlog.snap
  echo $(date) "--> incremental archive created"
else
  echo creating folder
  mkdir $this_week_dir
  echo $(date) "--> creating archive"
  sudo tar -cpzf $this_week_dir/full_dump.tgz -C /mnt -g $this_week_dir/tarlog.snap geoserver_data
  sudo cp $this_week_dir/tarlog.snap $this_week_dir/tarlog_lev0.snap
  echo $(date) "--> archive created"
fi

# SHORT NOTE ON HOW-TO RESTORE: firstly restore the full dump, then restore an incremental dump on top of it
# restoring the full dump (example)
# sudo tar xpzf full_dump.tgz -C /destination/folder

# restoring incremental dump (example)
# sudo tar xpzf incr_dump.tgz -C /destination/folder --listed-incremental=/dev/null

# restoring a single file (example): include the full path to the file on the archive, as it is printed with tar --list
# sudo tar xpzf full_dump.tgz -C /destination/folder geoserver-data/workspaces/geonode/osm_extracts/schools_point_osm/layer.xml

# now deleting old folders
bck_dir=/mnt/auto_bck/geoserver_bck

ws=$(echo 01)
for w in $(seq -w 5 4 52)
do
 ws=$(echo $ws"|"$w)
done

wre=$(echo "201[6-9]week("$ws")")
for dir in $(ls $bck_dir | head -n -3 | grep -Ev $wre)
do
 echo removing $dir
 sudo rm -r $(echo $bck_dir"/"$dir)
done

echo "-----------------------------------------------------------------"
echo $(date) "--> starting bck static folder"

sthis_week_dir=/mnt/auto_bck/geonode_statics/$(date +"%Yweek%W")
echo "checking backup folder -->" $sthis_week_dir

if [ -e $sthis_week_dir ]
then
  echo folder exists
else
  echo creating folder
  mkdir $sthis_week_dir
fi

echo $(date) "--> starting copy"
cp -L -R --preserve=all -u --backup=numbered /var/www/geonode/ $sthis_week_dir
echo $(date) "--> copy complete"

bck_dir=/mnt/auto_bck/geonode_statics

ws=$(echo 01)
for w in $(seq -w 5 4 52)
do
 ws=$(echo $ws"|"$w)
done

wre=$(echo "201[6-9]week("$ws")")
for dir in $(ls $bck_dir | head -n -3 | grep -Ev $wre)
do
 echo removing $dir
 rm -r $(echo $bck_dir"/"$dir)
done


sudo umount -d /dev/xvdg

echo "end of procedure"
