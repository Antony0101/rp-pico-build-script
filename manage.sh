#!/bin/bash

# This script is used to manage the application
# Commands:
#   - init: Initialize the application and clone raspberrypi sdk
#   - build: Build the application

# Input command
COMMAND=$1
SCRIPT_DIR=$(dirname "$(realpath "$0")")

case $COMMAND in
    init)
        echo "Initializing the application..."
        echo "Please enter the project name: "
        read PROJECT_NAME
        echo "Please enter the name of main file: "
        read MAIN_FILE
        if( [ ! -f $MAIN_FILE ] ); then
            touch $MAIN_FILE
        fi
        echo "cloning raspberrypi sdk..."
        if [ ! -d "pico-sdk" ]; then
            git clone https://github.com/raspberrypi/pico-sdk.git
        fi
        echo "creating artifacts..."
        if [ -d "pico-artifacts" ]; then
            rm -rf pico-artifacts
        fi
        mkdir pico-artifacts
        cp -r pico-sdk/external/pico_sdk_import.cmake ./
        if [ -f "CMakeLists.txt" ]; then
            rm CMakeLists.txt
        fi
        touch CMakeLists.txt
        cat <<EOF >>"CMakeLists.txt"

# Minimum CMake version required
cmake_minimum_required(VERSION 3.13...3.27)

# Initialize the SDK based on PICO_SDK_PATH
# Note: This must happen before project()
include(pico_sdk_import.cmake)

# Define the project
project(my_project)

# Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# Rest of your project
add_executable($PROJECT_NAME
    $MAIN_FILE
)

# Add pico_stdlib library which aggregates commonly used features
target_link_libraries($PROJECT_NAME pico_stdlib)

# Create map/bin/hex/uf2 file in addition to ELF
pico_add_extra_outputs($PROJECT_NAME)
EOF
        echo "create project configuration..."
        if [ -f "settings.json" ]; then
            rm settings.json
        fi
        touch settings.json
        cat <<EOF >>"settings.json"
{
    "project_name": "$PROJECT_NAME",
    "main_file": "$MAIN_FILE"
}
EOF
        echo "building cmake configuration..."
        cd pico-artifacts
        cmake -DPICO_SDK_PATH=$SCRIPT_DIR/pico-sdk ..
        echo "init is done"
        ;;
    build)
        if [ ! -d "pico-artifacts" ]; then
            echo "Please run 'init' command first"
            exit 1
        fi
        if [ ! -f "settings.json" ]; then
            echo "Please run 'init' command first"
            exit 1
        fi
        PROJECT_NAME=$(jq -r '.project_name' settings.json)
        echo "Building the application..."
        cd pico-artifacts
        make
        if [ -d "../build" ]; then
            rm -rf ../build
        fi
        mkdir ../build
        echo "copying the built files..."
        # cp -r *.uf2 build/
        cp -r $PROJECT_NAME.* ../build/
        ;;
esac