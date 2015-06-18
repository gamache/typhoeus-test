#!/usr/bin/env ruby
require 'json'

all_results = []

FILES = `ls *ruby*.json`.split(/\s+/)
FILES.each do |filename|
  results = JSON.parse(File.read(filename.chomp)) rescue nil
  if results and m=filename.match(/(j?ruby)-sleep-(\d+)/)
    exec = m[1]
    delay = m[2].to_i
    all_results << results.map do |result|
      result.merge(
        'executable' => exec,
        'delay_ms' => delay,
        'parameters' => "#{exec}, response delay #{delay} ms"
      )
    end
  end
end

puts JSON.pretty_generate(all_results.flatten)

    
  
