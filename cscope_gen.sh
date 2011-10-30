#!/bin/bash

find . -name "*.[chly]" \
-o -name "*.cpp"        \
-o -name "*.cxx"        \
-o -name "*.cc"         \
-o -name "*.inc"        \
-o -name "*.hpp"        \
-o -name "*.hh"         \
-o -name "*.py"         \
-o -name "*.java"       \
> cscope.files

cscope -bq
