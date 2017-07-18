#!/bin/sh
./rtokenize.rb --yaml < "$1" > out.yaml.token && ./rlocalize.rb yaml out.yaml.token "$1" 0
