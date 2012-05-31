#!/bin/bash

SOURCE=`basename $1`
TARGET=`echo $SOURCE | cut -d'.' -f1`

gcc $SOURCE -o $TARGET -ggdb
