#!/usr/bin/env ruby
# encoding: utf-8

class Serial
  def initialize(log, serial)
    @logger = log
    @serialport = SerialPort.new(serial[0], serial[1])
    ObjectSpace.define_finalizer(self) {
      @serialport.close
      @log.info("SerialPort Closed")
    }
  end

  def get_sensor_value(sensor)
    case(sensor)
    when "illumination"
      @serialport.puts "1\n"
    when "temp"
      @serialport.puts "2\n"
    else
      return false
    end

    return @serialport.gets.chomp!.to_i
  end

  def get_all_sensor_value
    return {"temp" => get_sensor_value("temp"), "illumi" => get_sensor_value("illumination")}
  end
end

dir = File.expand_path(File.dirname(__FILE__))
begin
  ENV['BUNDLE_GEMFILE'] = File.expand_path(File.join(dir, 'Gemfile'))
  require 'bundler/setup'
rescue
  puts "Error: 'bundler' not found."
  puts "Please install bundler with 'gem install bundler'."
end

require 'yaml'
config_file = File.join(dir, 'config.yml')
if File.exist?(config_file)
  config = YAML.load_file(config_file)
else
  puts "Error: 'config.yml' not found."
  puts "Please create 'config.yml'"
end

require 'logger'
log = Logger.new(STDOUT)
log.level = Logger::INFO
log.info("HAIMS client started")

require 'serialport'
boards = {}
config["board"].each do |key, board_conf|
  board_conf[1]["parity"] = SerialPort::NONE if board_conf[1]["parity"] == "none"
  boards.store(key, Serial.new(log, board_conf))
end

print "Please wait..."
3.downto(0) do |i|
  print " #{i}"
  if i != 0
    sleep 1
  else
    puts ""
  end
end

require 'sinatra'
require 'json'
get '/haims/api/sensors' do
  # 必須パラメータのチェック
  if params[:board].nil?
    {"error" => "Required parameter 'board' not found."}.to_json
    return
  end

  if params[:sensor].nil?
    boards[params[:board]].get_all_sensor_value.to_json
  else
    result = boards[params[:board]].get_sensor_value(params[:sensor])
    if result == false
      {"error" => "Invalid sensor name."}.to_json
    else
      {params[:sensor] => result}.to_json
    end
  end
end
