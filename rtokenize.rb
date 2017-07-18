#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'optparse'
require 'pry'

def panic(rcode, msg, e)
  STDERR.puts msg
  STDERR.puts(e) if e
  exit(rcode)
end

$toi = 0
$pi = 0

def emit_token(tok, lit = nil)
  $pi += 1
  if lit
    lit = lit.to_s.gsub(/\n/, ' ')
    "#{$toi}:#{$pi}\t#{tok}|\"#{lit}\"\n"
  else
    "#{$toi}:#{$pi}\t#{tok}|#{tok}\n"
  end
end

def traverse_object(repr, o, oname = nil)
  $toi += 1
  $pi = 0
  repr += emit_token('TYPE', o.class)
  case o
  when Hash
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('{')
    o.each do |k, v|
      repr += emit_token('KEY', k)
      opi = $pi
      repr = traverse_object(repr, v, k)
      $pi = opi
      repr += emit_token(',')
    end
    repr += emit_token('}')
  when Array
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('[')
    o.each_with_index do |r, i|
      repr += emit_token('INDEX', i)
      opi = $pi
      repr = traverse_object(repr, r)
      $pi = opi
      repr += emit_token(',')
    end
    repr += emit_token(']')
  when NilClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('NULL')
  when TrueClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('TRUE')
  when FalseClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('FALSE')
  when String
    repr += emit_token('IDENT', oname) if oname
    o.split("\n").each do |ol|
      repr += emit_token('STRING', ol)
    end
  when Symbol
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('SYMBOL', o)
  when Fixnum
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('INT', o)
  when Float
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('FLOAT', o)
  when Bignum
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('BIGNUM', o)
  when Time
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('TIME', o)
  when Date
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('DATE', o)
  else
    panic(4, "Unknown class #{o.class}", nil)
  end
  repr
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: rtokenize.rb [options]"
  opts.on("-j", "--json", "Input is JSON") do |v|
    options[:json] = true
  end
  opts.on("-y", "--yaml", "Input is YAML") do |v|
    options[:yaml] = true
  end
end.parse!

parser = nil
parser = JSON if options.key?(:json)
parser = YAML if options.key?(:yaml)
panic(1, 'No parser defined', nil) unless parser

in_data = STDIN.read
parse_error = 0
while true
  data = ''
  begin
    # STDERR.puts "PARSE: error=#{parse_error}, len=#{in_data.length}"
    data = parser.load(in_data)
  rescue Exception => e
    if parse_error == 0
      in_data.gsub!('{{', '<<')
      in_data.gsub!('}}', '>>')
    elsif parse_error == 1
      in_data.gsub!('{%', '<%')
      in_data.gsub!('%}', '%>')
    elsif parse_error == 2
      in_data.gsub!(/<%.*%>/, '')
    elsif parse_error == 3
      in_data.gsub!(/\${.*}/, '')
    elsif parse_error == 4
      in_data.gsub!(/\$(.*)/, '')
    elsif parse_error == 5
      in_data.gsub!(/<<.*>>/, '')
      #STDERR.puts in_data
    else
      panic(2, "Parse error", e) 
    end
    parse_error += 1
    next
  end
  break
end

repr = "-:-\tbegin_unit\n"
begin
  repr = traverse_object(repr, data)
rescue Exception => e
  panic(3, "Traverse error", e)
end
repr += "-:-\tend_unit\n"

puts repr
