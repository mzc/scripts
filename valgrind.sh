#!/bin/bash

valgrind -v --leak-check=full --show-reachable=yes --track-origins=yes --db-attach=yes "$@"
