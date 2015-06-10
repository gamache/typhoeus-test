#!/usr/bin/env ruby
require 'typhoeus'
require 'benchmark'
require 'json'

if ARGV.count < 2 || ARGV.count > 4
  STDERR.puts "Usage: #{$0} method url [request_count [repeat_count]]\n"
  exit 1
end

METHOD = ARGV.shift.upcase
URL = ARGV.shift
REQUEST_COUNT = (ARGV.shift || 500).to_i
REPEAT_COUNT = (ARGV.shift || 10).to_i

CONCURRENCIES = [1, 2, 3, 4, 5, 10, 20, 40, 60, 80,
                 100, 120, 140, 160, 180, 200]

concurrency_stats = {}

REPEAT_COUNT.times do
  CONCURRENCIES.each do |concurrency|
    start_time = Time.now.to_f
    hydra = Typhoeus::Hydra.new
    request_number = 0

    queue_next_request = lambda do
      if request_number < REQUEST_COUNT
        req = Typhoeus::Request.new(URL, :method => METHOD)
        req.on_complete {|resp| queue_next_request.call }
        hydra.queue(req)
        request_number += 1
      end
    end

    concurrency.times { queue_next_request.call }

    bm = Benchmark.measure { hydra.run }
    elapsed = Time.now.to_f - start_time

    concurrency_stats[concurrency] ||= []
    concurrency_stats[concurrency] << {
      'requests_per_second' => REQUEST_COUNT / elapsed,
      'cpu_percentage' => (bm.total / elapsed) * 100
    }
  end
end

output_stats = concurrency_stats.map do |concurrency, stats|
  avg_rps = stats.map{|s| s['requests_per_second']}.reduce(:+) / stats.count
  avg_cpu = stats.map{|s| s['cpu_percentage']}.reduce(:+) / stats.count
  {
    'concurrency' => concurrency,
    'requests_per_second' => ('%.2f' % avg_rps).to_f,
    'cpu_percentage' => ('%.2f' % avg_cpu).to_f
  }
end

puts JSON.pretty_generate(output_stats)
