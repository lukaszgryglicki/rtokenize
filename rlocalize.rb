#!/usr/bin/env ruby

def panic(why)
  STDERR.puts why
  exit 1
end

def lookup_token(ft, tp, val, buf, bufdc, pos)
  tp = tp.downcase
  STDERR.puts [tp, val] unless val[0] == '"'
  val = val[1..-2]
 
  skip_types = []
  exact_types = []
  dc_types = []
  case ft
  when 'y'
    skip_types = %w(type index syntax)
    exact_types = %w(ident key string symbol int bignum)
    dc_types = %w(boolean float date time)
  when 'j'
    skip_types = %w(type index)
    exact_types = %w(ident syntax key string symbol int bignum)
    dc_types = %w(boolean float date time)
  else
    panic("Unknown token file type: #{ft}")
  end

  case tp
  when *skip_types
  when *exact_types
    npos = buf.index(val, pos)
    if tp == 'string' && !npos
      val = val.gsub(/'/, "''")
      npos = buf.index(val, pos)
    end
    if tp == 'string' && !npos
      val = val.gsub(/"/, '\"')
      npos = buf.index(val, pos)
    end
    if npos
       # puts "#{tp}: #{val} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{val}' not found starting at #{pos}"
    end
  when *dc_types
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
    pos = lookup_token(ftype, ttype, tvalue, buf, bufdc, pos)
    # puts "Type: #{ttype}, Value: '#{tvalue}' --> #{pos}"
  end
end

if ARGV.size < 2
  puts "Missing arguments: [yaml|json] file.token file.orig [start_pos]"
  exit(1)
end

rlocalize(ARGV)
