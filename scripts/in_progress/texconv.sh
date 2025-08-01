#!/bin/bash
## texconv is a texture converter tool for Sega Dreamcast development.
## It provides a graphical user interface (GUI) to convert standard image files into the PVR format,
## which is the native texture format for the Dreamcast's PowerVR graphics hardware.

# Install texconv dependencies
apt-get install -y --no-install-recommends \
	qt5-qmake qtbase5-dev qtbase5-dev-tools libqt5svg5-dev \
	libqt5webenginewidgets5 libqt5webchannel5-dev qtwebengine5-dev

https://github.com/tvspelsfreak/texconv.git 

