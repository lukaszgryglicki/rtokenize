#!/usr/bin/env ruby

def panic(why)
  STDERR.puts why
  exit 1
end

def lookup_token_yaml(tp, val, buf, bufdc, pos)
  tp = tp.downcase
  STDERR.puts [tp, val] unless val[0] == '"'
  val = val[1..-2]
  case tp
  when 'type', 'index', 'syntax'
  when 'ident', 'key', 'string', 'symbol', 'int', 'bignum'
    npos = buf.index(val, pos)
    if npos
       # puts "#{tp}: #{val} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{val}' not found starting at #{pos}"
    end
  when 'boolean', 'float', 'date', 'time'
    valdc = val.downcase
    npos = bufdc.index(valdc, pos)
    if npos
       # puts "#{tp}: #{valdc} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{valdc}' not found starting at #{pos}"
    end
  end
  pos
end
    
def lookup_token_json(tp, val, buf, bufdc, pos)
  tp = tp.downcase
  STDERR.puts [tp, val] unless val[0] == '"'
  val = val[1..-2]
  case tp
  when 'type', 'index'
  when 'ident', 'syntax', 'key', 'string', 'symbol', 'int', 'bignum'
    npos = buf.index(val, pos)
    if npos
       # puts "#{tp}: #{val} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{val}' not found starting at #{pos}"
    end
  when 'boolean', 'float', 'date', 'time'
    valdc = val.downcase
    npos = bufdc.index(valdc, pos)
    if npos
       # puts "#{tp}: #{valdc} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{valdc}' not found starting at #{pos}"
    end
  end
  pos
end

def rlocalize(args)
  ftype = args[0][0]
  ftoken = args[1]
  forig = args[2]
  pos = (args[3] || 0).to_i
  buf = File.read(forig)
  bufdc = buf.downcase
  types = %w(BIGNUM BOOLEAN DATE FLOAT IDENT INDEX INT KEY NULL STRING SYMBOL SYNTAX TIME TYPE)
  File.readlines(ftoken).each do |line|
    ta = line.strip.split('|')
    ttype = ta[0]
    tvalue = ta[1]
    panic("Unknown token type: #{ttype}") unless types.include?(ttype)
    pos = lookup_token_json(ttype, tvalue, buf, bufdc, pos) if ftype == 'j'
    pos = lookup_token_yaml(ttype, tvalue, buf, bufdc, pos) if ftype == 'y'
    # puts "Type: #{ttype}, Value: '#{tvalue}' --> #{pos}"
  end
end

if ARGV.size < 2
  puts "Missing arguments: [yaml|json] file.token file.orig [start_pos]"
  exit(1)
end

rlocalize(ARGV)
