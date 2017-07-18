#!/bin/sh
./rtokenize.rb --json < "$1" > out.json.token && ./rlocalize.rb json out.json.token "$1" 0
