#!/usr/bin/env ruby

require 'yaml'

yf = File.read(ARGV.first)
y = YAML.load(yf)
ys = y.to_yaml
puts ys
