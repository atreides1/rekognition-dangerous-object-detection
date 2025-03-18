#! /usr/bin/env bash
# make sure to setup your AWS credentials for the cli

# prerequisites
sudo apt-get update
sudo apt-get install build-essential
sudo apt-get install pkg-config
sudo apt-get install cmake
sudo apt-get install m4
sudo apt-get install openjdk-8-jdk
sudo apt-get install default-jdk
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio
sudo apt-get install libssl-dev libcurl4-openssl-dev liblog4cplus-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-tools
sudo apt install build-essential dkms linux-headers-$(uname -r)

# download the producer sdk
git clone https://github.com/awslabs/amazon-kinesis-video-streams-producer-sdk-cpp.git

cd amazon-kinesis-video-streams-producer-sdk-cpp/
mkdir build
cd build
cmake .. -DBUILD_GSTREAMER_PLUGIN=ON -DBUILD_JNI=TRUE
make

cd ..
export GST_PLUGIN_PATH=`pwd`/build
export LD_LIBRARY_PATH=`pwd`/open-source/local/lib
export JAVA_HOME="/usr/lib/jvm/default-java"
cd build/

# send stream to the specified kinesis video stream
gst-launch-1.0 v4l2src do-timestamp=TRUE device=/dev/video0 ! jpegdec ! videoconvert ! \
    video/x-raw,format=I420,width=640,height=480,framerate=30/1 ! x264enc  bframes=0 key-int-max=45 bitrate=500 ! \
    video/x-h264,stream-format=avc,alignment=au,profile=baseline ! kvssink stream-name="my-video-stream" storage-size=512 \ 
    access-key="$AWS_ACCESS_KEY_ID" secret-key="$AWS_SECRET_ACCESS_KEY" aws-region="$AWS_DEFAULT_REGION"

# the following commands can be used for debugging:

# are gstreamer and the kvssink plugin set up correctly?
# gst-inspect-1.0 kvssink

# what format is my camera? (could be located at /dev/video1)
# v4l2-ctl -d /dev/video0 --list-formats-ext

# is my video stream working? (sends stream to fakesink)
# gst-launch-1.0 v4l2src do-timestamp=TRUE device=/dev/video0 ! jpegdec ! videoconvert ! video/x-raw,format=I420,width=640,height=480,framerate=30/1 ! x264enc  bframes=0 key-int-max=45 bitrate=500 ! video/x-h264,stream-format=avc,alignment=au,profile=baseline ! fakesink sync=false
