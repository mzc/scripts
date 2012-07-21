#!/bin/bash

valgrind -v --tool=memcheck --leak-check=full --show-reachable=yes --track-origins=yes --db-attach=yes "$@"
