#!/usr/bin/env ruby

require 'rubygems' rescue nil

require 'qmf'
require 'mrg/grid/config-client'
require 'mrg/grid/config-proxies'

host = "localhost"
port = 5672
username = nil
password = nil
debug = :warn

op = OptionParser.new do |opts|
  opts.banner = "Usage store-dump.rb [options]"

  opts.on("-h", "--host HOSTNAME", "qpid broker host (default localhost)") do |h|
    host = h
  end

  opts.on("-p", "--port NUM", "qpid broker port (default 5672)") do |num|
    port = num.to_i
  end

  opts.on("-U", "--user NAME", "qpid username") do |name|
    username = name
  end

  opts.on("-P", "--password PASS", "qpid password") do |pass|
    password = pass
  end
end

begin
  op.parse!
rescue OptionParser::InvalidOption
  puts op
  exit
end

console = Qmf::Console.new

settings = Qmf::ConnectionSettings.new
settings.username = username if username
settings.password = password if password
settings.host = host
settings.port = port

connection = Qmf::Connection.new(settings)

broker = console.add_connection(connection)

broker.wait_for_stable

store = console.object(:class=>"Store")

s = Mrg::Grid::SerializedConfigs::ConfigSerializer.new(store, true, console)

serialized = s.serialize

puts serialized.to_yaml
