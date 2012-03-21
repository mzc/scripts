#!/bin/bash

SOURCE=$1
TARGET=`echo $SOURCE | cut -d'.' -f1`

g++ $SOURCE -o $TARGET
