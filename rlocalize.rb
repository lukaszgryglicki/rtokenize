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
    dc_types = %w(float date time)
  when 'j'
    skip_types = %w(type index)
    exact_types = %w(ident syntax key string symbol int bignum)
    dc_types = %w(float date time)
  else
    panic("Unknown token file type: #{ft}")
  end

  case tp
  when *skip_types
  when *exact_types
    npos = buf.index(val, pos)
    # if tp == 'string' && !npos # XXX
    if !npos
      val = val.gsub(/'/, "''")
      npos = buf.index(val, pos)
    end
    if !npos
      val = val.gsub(/"/, '\"')
      npos = buf.index(val, pos)
    end
    if npos
       # puts "full: #{tp}: #{val} found at #{npos} starting at #{pos}"
       pos = npos
    else
      oldpos = pos
      # STDERR.puts "#{tp}: '#{val}' not found starting at #{pos}"
      val.split.each do |word|
        npos = buf.index(word, pos)
        if npos
          # puts "word: #{tp}: #{word} found at #{npos} starting at #{pos}"
          pos = npos
        else
          nwords = word.split(/[^a-zA-Z0-9_ ]/).reject { |s| s == '' }
	  nwords.each do |w|
            puts "'#{val}' --> '#{word}' --> '#{w}', pos=#{pos}"
            npos = buf.index(w, pos)
            if npos
              # puts "problematic #{tp}: #{word} found at #{npos} starting at #{pos}"
              pos = npos
            else
              STDERR.puts "splitted word: #{tp}: '#{w}'/'#{word}/'#{val}' not found starting at #{pos}"
            end
          end
        end
      end
      if pos == oldpos
        STDERR.puts "VERY BAD: #{tp}: '#{val}' not found starting at #{pos}" # XXX
        # panic "bye bye cruel world!"
      end
    end
  when *dc_types
    valdc = val.downcase
    valdc = valdc.split(' ').first if tp == 'time'
    npos = bufdc.index(valdc, pos)
    if npos
       # puts "dc: #{tp}: #{valdc} found at #{npos} starting at #{pos}"
       pos = npos
    else
      STDERR.puts "#{tp}: '#{valdc}' not found starting at #{pos}" unless npos
    end
  when 'boolean'
    valdc = val.downcase
    vals = %w(off no false disabled) if valdc == 'false'
    vals = %w(on yes true enabled) if valdc == 'true'
    npos = {}
    vals.each do |v|
      npos[v] = bufdc.index(v, pos)
    end
    npos = npos.values.compact.min
    if npos
      # puts "boolean: #{tp}: #{valdc}/equivalent found at #{npos} starting at #{pos}"
      pos = npos
    else
      STDERR.puts "#{tp}: '#{valdc}' not found starting at #{pos}" unless npos
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
