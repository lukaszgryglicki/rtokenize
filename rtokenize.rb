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
$opts = nil

def emit_token(tok, lit = nil)
  $pi += 1
  start = $opts.key?(:nums) ? "#{$toi}:#{$pi}\t" : ''
  if lit
    lit = lit.to_s.gsub(/\n/, ' ')
    "#{start}#{tok}|\"#{lit}\"\n"
  else
    "#{start}#{tok}\n"
  end
end

def split_if_needed(str)
  return [str] unless $opts.key?(:split) and $opts.key?(:split_part_size)
  spl = $opts[:split]
  sps = $opts[:split_part_size]
  sl = str.length
  return [str] unless sl > spl
  stra = str.split(' ')
  s = []
  res = []
  ps = spl
  stra.each do |word|
    tmp = s + [word]
    #STDERR.puts "word: #{word} --> tmp: #{tmp.to_s}, join_len: #{tmp.join(' ').length}"
    if tmp.join(' ').length <= ps
      s << word
      #STDERR.puts "added word: #{word}, s: #{s.to_s}"
    else
      res << s.join(' ') if s.length > 0
      s = [word]
      ps = sps
      #STDERR.puts "Added phrase: res: #{res.to_s}, s: #{s.to_s}"
    end
  end
  if s.length > 0
    res << s.join(' ')
    #STDERR.puts "Added final: res: #{res.to_s}, s: #{s.to_s}"
  end
  #STDERR.puts [stra, str, res, s].map(&:to_s)
  #STDERR.puts res.to_s
  res
end

def traverse_object(repr, o, oname = nil)
  $toi += 1
  $pi = 0
  repr += emit_token('TYPE', o.class)
  case o
  when Hash
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('SYNTAX', '{')
    l = o.count - 1
    o.keys.each_with_index do |k, i|
      v = o[k]
      repr += emit_token('KEY', k)
      opi = $pi
      repr = traverse_object(repr, v, k)
      $pi = opi
      repr += emit_token('SYNTAX', ',') if i < l
    end
    repr += emit_token('SYNTAX', '}')
  when Array
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('SYNTAX', '[')
    l = o.count - 1
    o.each_with_index do |r, i|
      repr += emit_token('INDEX', i)
      opi = $pi
      repr = traverse_object(repr, r)
      $pi = opi
      repr += emit_token('SYNTAX',',') if i < l
    end
    repr += emit_token('SYNTAX',']')
  when NilClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('NULL', 'NULL')
  when TrueClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('BOOLEAN', 'TRUE')
  when FalseClass
    repr += emit_token('IDENT', oname) if oname
    repr += emit_token('BOOLEAN', 'FALSE')
  when String
    repr += emit_token('IDENT', oname) if oname
    o.split("\n").each do |ol|
      oa = split_if_needed(ol)
      oa.each { |osp| repr += emit_token('STRING', osp) }
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
  opts.on("-n", "--numbers", "Output parsing numbers") do |v|
    options[:nums] = true
  end
  opts.on("-h", "--header", "Output begin_unit & end_unit") do
    options[:header] = true
  end
  opts.on("-s N", "--split N", Integer, "Split strings longer than N") do |n|
    options[:split] = n
  end
  opts.on("-p N", "--part-size N", Integer, "Split string part size P for strings longer than N") do |p|
    options[:split_part_size] = p
  end
end.parse!

parser = nil
parser = JSON if options.key?(:json)
parser = YAML if options.key?(:yaml)
panic(1, 'No parser defined', nil) unless parser

in_data = STDIN.read
if options.key?(:yaml)
  in_data.gsub!('{{', '<<')
  in_data.gsub!('}}', '>>')
end
parse_error = 0
multi_json = false

while true
  data = ''
  begin
    # STDERR.puts "PARSE: error=#{parse_error}, len=#{in_data.length}"
    data = parser.load(in_data)
  rescue Exception => e
    if options.key?(:yaml)
      if parse_error == 0
        in_data.gsub!('{%', '<%')
        in_data.gsub!('%}', '%>')
      elsif parse_error == 1
        in_data.gsub!(/<%.*%>/, '')
      elsif parse_error == 2
        in_data.gsub!(/\${.*}/, '')
      elsif parse_error == 3
        in_data.gsub!(/\$(.*)/, '')
      elsif parse_error == 4
        in_data.gsub!(/<<.*>>/, '')
        #STDERR.puts in_data
      else
        panic(2, "YAML Parse error", e) 
      end
    elsif options.key?(:json)
      if parse_error == 0
        in_data = '[' + in_data.gsub("}\n{", "},{") + ']'
        multi_json = true
      else
        panic(2, "JSON Parse error", e) 
      end
    else
       panic(3, "Unknown language #{options.to_s}", e)
    end
    parse_error += 1
    next
  end
  break
end

if multi_json && data.length == 0
  panic(4, "Empty JSON in #{in_data[1..-2]}", nil)
end

$opts = options
repr = options.key?(:header) ? (options.key?(:nums) ? "-:-\tbegin_unit\n" : "begin_unit\n") : ''
begin
  repr += emit_token('FILETYPE', 'json') if options.key?(:json)
  repr += emit_token('FILETYPE', 'yaml') if options.key?(:yaml)
  repr += emit_token('MULTI', 'MULTI') if multi_json
  repr = traverse_object(repr, data)
#rescue Exception => e
#  panic(3, "Traverse error", e)
end
if options.key?(:header)
  repr += options.key?(:nums) ? "-:-\tend_unit\n" : "end_unit\n"
end

puts repr
