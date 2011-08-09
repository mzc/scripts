#!/bin/bash

emacsclient -c -a "" --eval "( ediff \"$2\" \"$5\" )"
