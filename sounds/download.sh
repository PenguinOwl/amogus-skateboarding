#! /bin/bash

youtube-dl -f 140 $1 -o /tmp/sound-download.m4a --force-overwrites
# ffmpeg -i /tmp/sound-download.m4a -af "silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=-60dB:detection=peak,aformat=dblp,areverse" $2.ogg -y
ffmpeg -i /tmp/sound-download.m4a $2.ogg -y

