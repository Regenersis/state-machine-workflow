require "rubygems"
require "bundler/setup"
require File.join(File.dirname(__FILE__),'../lib/state_machine_workflow')

Dir[File.dirname(__FILE__) + "/support/*.rb"].each{|file| require file}
