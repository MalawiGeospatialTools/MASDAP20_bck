#!/bin/bash
# geonode backupper
echo "*****************************************************************"
echo "-----------------------------------------------------------------"
echo "*****************************************************************"

echo

#sudo mount /dev/xvdg /mnt/auto_bck
bck_root=/mnt/data/auto-bck
pg_bck_root=$bck_root/pg_dumps
today_dir=$pg_bck_root/$(date +"%Y%m%d")_dump
echo "creating backup folder -->" $today_dir
mkdir $today_dir

echo $(date) "--> dumping geonode db"
pg_dump -Fc -U postgres geonode > $today_dir/geonode.dump
echo $(date) "--> geonode db dumped"

echo $(date) "--> dumping geonode_data db"
pg_dump -Fc -b -U postgres geonode_data > $today_dir/geonode_data.dump
echo $(date) "--> geonode_data db dumped"

# removing old folders

# get current month
cur_m=$(date +%m)
# get previous month
prev_m=$(expr $cur_m - 1)
# get previous month with leading 0
prev_m2=$(printf "%02d" $prev_m)
# build re that matches current and previous month backups
re=$(echo "201[6-9]("$cur_m"|"$prev_m2")")
# loop on backups in days other than 01, 08, 15, 23
for dir in $(ls $pg_bck_root | head -n -7 | grep -E $re | grep -Ev \
'(01|08|15|23)_dump')
do
 echo removing $dir
 rm -r $(echo $pg_bck_root"/"$dir)
done

echo "end of dumping procedure"

echo "-----------------------------------------------------------------"
echo $(date) "--> starting bck for geoserver data folder"

data_dir_parent=/mnt/data
gs_bck_root=$bck_root/geoserver_bck
this_week_dir=$gs_bck_root/$(date +"%Yweek%W")
echo "checking backup folder -->" $this_week_dir

if [ -e $this_week_dir ]
then
  echo folder exists
  echo $(date) "--> creating incremental archive"
  sudo tar -cpzf $this_week_dir/incr_dump.tgz -C $data_dir_parent -g $this_week_dir/tarlog.snap --backup=numbered geoserver-data
  sudo cp $this_week_dir/tarlog_lev0.snap $this_week_dir/tarlog.snap
  echo $(date) "--> incremental archive created"
else
  echo creating folder
  mkdir $this_week_dir
  echo $(date) "--> creating archive"
  sudo tar -cpzf $this_week_dir/full_dump.tgz -C $data_dir_parent -g $this_week_dir/tarlog.snap geoserver-data
  sudo cp $this_week_dir/tarlog.snap $this_week_dir/tarlog_lev0.snap
  echo $(date) "--> archive created"
fi

# now deleting old folders
bck_dir=/mnt/auto_bck/geoserver_bck

ws=$(echo 01)
for w in $(seq -w 5 4 52)
do
 ws=$(echo $ws"|"$w)
done

wre=$(echo "201[6-9]week("$ws")")
for dir in $(ls $gs_bck_root | head -n -3 | grep -Ev $wre)
do
 echo removing $dir
 sudo rm -r $(echo $gs_bck_root"/"$dir)
done

echo "-----------------------------------------------------------------"
echo $(date) "--> starting geonode backup"
python /home/ubuntu/geonode_bck/backup-restore/backup.py
mv /home/ubuntu/backup/* /mnt/data/auto-bck/static
echo $(date) "--> geonode backup complete"

echo "end of procedure"
