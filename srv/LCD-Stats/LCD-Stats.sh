#!/bin/sh
#LCD-Stats displays:
#--Hostname
#--IP address
#--Available hard drive space
#--Device temp
#--CPU and RAM utilization
#Information is displayed on the 160x60 LCD screen. Includes ability to play PNG frame video during boot up.
#Install ImageMagick and Lm-Sensors.
#--apt -y install imagemagick lm-sensors
#Copy LCD-Stats.sh and Video folder to /srv/LCD-Stats/. Copy LCD-Stats.service to the folder /lib/systemd/system/ then run:
#--systemctl daemon-reload && systemctl enable LCD-Stats.service

#Turn LCD off then on and set brightness low (0-15).
  echo 1 > /sys/class/graphics/fb0/blank
  echo 0 > /sys/class/graphics/fb0/blank
  echo 1 > /sys/class/backlight/fb_sp8110/brightness
#Variable for LCD on/off time
  LCDTime=10
#Variable for switching between Hostname and IP.
  NameIP=1
#Variable for switching between drives.
  DriveNum=0
#Variable for font name.
  MyFont=Noto-Mono
#Variable for device IP.
  MyIP=$(hostname -I)
#Variable for hastname.
  Hostname=$(hostname)
#Wait 5 seconds for device to boot before starting script.
  sleep 5s
#Play video at boot.
  for image in /srv/LCD-Stats/Video/*.png; do
    /sbin/ck-splash -f "$image"
    sleep 0.02s
  done
#Hold last frame for 1 second.
  sleep 1s
#Loop forever.
  while [ true ]
  do
    #Get CPU and RAM utilization.
      CPU=$(/usr/bin/top -bn1 | grep "Cpu(s)" | /bin/sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | /usr/bin/awk '{print 100 - $1"%"}')
      RAM=$(/usr/bin/free -m | /usr/bin/awk 'NR==2{printf "%.1f%%\n", $3*100/$2 }')
    #Get device temparture.
      Temp=$(sensors pm8953_tz-virtual-0 -f | awk '$2+0 {print $2}')
    #Get drive space.
      #1TB HDD
      Drive0=$(df -hl --output=size,used,target | grep /volume1)
      #Main 6 GB SSD partition
      Drive1=$(df -hl --output=size,used,target | grep /mnt/.rwfs)
      #Extra 19 GB SSD partition
      Drive2=$(df -hl --output=size,used,target | grep /data)
    #Turn LCD on/off every 5 minutes.
      if [ "$LCDTime" -lt 300 ]; then
        LCDTime=$(($LCDTime+10))
      elif [ "$LCDTime" -ge 300 ] && [ "$LCDTime" -lt 600 ]; then
        echo 0 > /sys/class/backlight/fb_sp8110/brightness
        echo 1 > /sys/class/graphics/fb0/blank
        LCDTime=$(($LCDTime+10))
      else
        echo 0 > /sys/class/graphics/fb0/blank
        echo 1 > /sys/class/backlight/fb_sp8110/brightness
        LCDTime=0
      fi
    #Creat black PNG file using ImageMagick.
      convert -size 160x60 xc:black /srv/LCD-Stats/LCD-Stats.png
    #Toggle between Hostname and IP Address.
      if [ "$NameIP" != 1 ]; then
        convert /srv/LCD-Stats/LCD-Stats.png -gravity north -undercolor black -fill white -font $MyFont -pointsize 14 -annotate +0+1 "$Hostname" /srv/LCD-Stats/LCD-Stats.png
        NameIP=1
      else
        convert /srv/LCD-Stats/LCD-Stats.png -gravity north -undercolor black -fill white -font $MyFont -pointsize 14 -annotate +0+1 "$MyIP" /srv/LCD-Stats/LCD-Stats.png
        NameIP=0
      fi
    #Fill in the rest of the data.
      convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+31 "Size  Used  Mount" /srv/LCD-Stats/LCD-Stats.png
    #Toggle between three drive partitions (/volume1, /mnt/.rwfs, /data)
      if [ "$DriveNum" = 0 ]; then
        convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+21 "$Drive0" /srv/LCD-Stats/LCD-Stats.png
        DriveNum=1
      elif [ "$DriveNum" = 1 ]; then
        convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+21 "$Drive1" /srv/LCD-Stats/LCD-Stats.png
        DriveNum=2
      else
        convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+21 "$Drive2" /srv/LCD-Stats/LCD-Stats.png
        DriveNum=0
      fi
    convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+11 "Temp: $Temp°F" /srv/LCD-Stats/LCD-Stats.png
    convert /srv/LCD-Stats/LCD-Stats.png -gravity south -undercolor black -fill white -font $MyFont -pointsize 8 -annotate +0+1 "CPU: $CPU  RAM: $RAM" /srv/LCD-Stats/LCD-Stats.png
    #Display PNG file on LCD.
      ck-splash -s image -f /srv/LCD-Stats/LCD-Stats.png
    sleep 10s
  done
