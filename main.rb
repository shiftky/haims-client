#!/usr/bin/env ruby
# encoding: utf-8

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

#require 'sinatra'
require 'serialport'
require 'logger'

log = Logger.new(STDOUT)
log.level = Logger::INFO
log.info("HAIMS client started")

serialport = SerialPort.new(config[:board][:main], 9600, 8, 1, SerialPort::NONE)
