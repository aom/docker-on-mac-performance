#!/usr/bin/env ruby

SEPARATOR = '------------------------------'

def parse_benchmark_filename(filename)
  filename_match = filename.split('-')
  [
    filename_match[1],
    filename_match[2],
    filename_match[3],
    filename_match[4],
    filename_match[5].split('.').first
  ]
end

def parse_benchmark_lines(file_contents)
  metrics = []
  metric = nil

  file_contents.lines
               .map(&:chomp)
               .each do |line|
    if metric
      case line
      when SEPARATOR
        next
      when ''
        metric = nil
        next
      end

      match = line.match(/(\d+)\sbytes\s\([\d\w\.\s]+\)\scopied,\s([\d\.]+)\ss,\s/)
      bytes = match[1]
      seconds = match[2]
    end

    if line == 'FS write performance'
      metric = 'disk'
      next
    end

    if line == 'CPU performance'
      metric = 'cpu'
      next
    end

    next if metric.nil?

    metrics << [
      metric,
      bytes,
      seconds
    ]
  end

  metrics
end

def parse_benchmark(filename, file_contents)
  (
    host,
    setup,
    vm,
    iteration,
    date
  ) = parse_benchmark_filename filename

  metrics = parse_benchmark_lines file_contents

  metrics.map do |metric|
    [
      host,
      setup,
      vm,
      iteration,
      date,
      filename,
      metric[0],
      metric[1],
      metric[2]
    ].join(',')
  end
end

if ARGV[0] == 'test'
  log = DATA.read
  log_filename = 'benchmark-host-setup-fusion-0-20170922125427.log'

  res = parse_benchmark log_filename, log

  throw "⚠️  not enough lines: #{res.size}" if res.size != 20
  throw "⚠️  sanity check failed" if res.last != 'host,setup,fusion,0,20170922125427,benchmark-host-setup-fusion-0-20170922125427.log,cpu,268435456,18.2075'

  puts "❤️  OK!"
  exit
end

dump_filename = "dumps/dump-#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"

puts SEPARATOR
puts "Dumping all metrics from logs/ to #{dump_filename}"
puts SEPARATOR
puts
dump = File.open(dump_filename, 'w')
dump.puts %w[
  host
  setup
  vm
  iteration
  date
  filename
  metric
  bytes
  seconds
].join(',')

Dir.glob('logs/*.log') do |file|
  puts "Parsing #{file}"
  parse_benchmark(file, File.read(file)).each do |line|
    print '.'
    dump.puts line
  end
  puts
end

dump.close

puts
puts SEPARATOR
puts 'Done'
puts SEPARATOR

system "open #{dump_filename}"



__END__
Client mode...
Target: 172.17.0.2
------------------------------
Performance benchmarks
------------------------------
dockerhost: tcp://192.168.99.100:2376
host: 172.17.0.2 570e68f8cc55
eth0: 172.17.0.2
date: Fri Sep 22 08:59:01 UTC 2017

------------------------------
FS write performance
------------------------------
1073741824 bytes (1.1 GB) copied, 0.466328 s, 2.3 GB/s
1073741824 bytes (1.1 GB) copied, 0.525009 s, 2.0 GB/s
1073741824 bytes (1.1 GB) copied, 0.459576 s, 2.3 GB/s
1073741824 bytes (1.1 GB) copied, 0.473238 s, 2.3 GB/s
1073741824 bytes (1.1 GB) copied, 0.68225 s, 1.6 GB/s
1073741824 bytes (1.1 GB) copied, 0.714613 s, 1.5 GB/s
1073741824 bytes (1.1 GB) copied, 0.458231 s, 2.3 GB/s
1073741824 bytes (1.1 GB) copied, 0.455166 s, 2.4 GB/s
1073741824 bytes (1.1 GB) copied, 0.450707 s, 2.4 GB/s
1073741824 bytes (1.1 GB) copied, 0.451178 s, 2.4 GB/s

------------------------------
CPU performance
------------------------------
268435456 bytes (268 MB) copied, 18.4383 s, 14.6 MB/s
268435456 bytes (268 MB) copied, 20.4133 s, 13.2 MB/s
268435456 bytes (268 MB) copied, 19.5224 s, 13.8 MB/s
268435456 bytes (268 MB) copied, 18.0854 s, 14.8 MB/s
268435456 bytes (268 MB) copied, 18.5986 s, 14.4 MB/s
268435456 bytes (268 MB) copied, 18.6324 s, 14.4 MB/s
268435456 bytes (268 MB) copied, 19.156 s, 14.0 MB/s
268435456 bytes (268 MB) copied, 18.0302 s, 14.9 MB/s
268435456 bytes (268 MB) copied, 25.7928 s, 10.4 MB/s
268435456 bytes (268 MB) copied, 18.2075 s, 14.7 MB/s

------------------------------
System info
------------------------------
             total       used       free     shared    buffers     cached
Mem:       2049492     896544    1152948     191436      28432     635100
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                7
On-line CPU(s) list:   0-6
Thread(s) per core:    1
Core(s) per socket:    7
Socket(s):             1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 158
Stepping:              9
CPU MHz:               4200.000
BogoMIPS:              8400.00
Hypervisor vendor:     KVM
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              8192K
