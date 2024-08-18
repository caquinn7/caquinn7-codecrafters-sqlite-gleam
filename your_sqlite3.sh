#!/bin/sh
#
# DON'T EDIT THIS!
#
# CodeCrafters uses this file to test your code. Don't make any changes here!
#
# DON'T EDIT THIS!
# exec gleam run -- "$@"
exec gleam run --module sqlite -- "$@" | grep -v "Compiled" | grep -v "Running" | grep -v "=ERROR REPORT=" | grep -v "backend port" | grep -v "^\n"
