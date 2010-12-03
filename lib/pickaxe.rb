require "rubygems"
require "bundler/setup"
require "active_support/all"

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

module Pickaxe
	VERSION = "0.5.3"
	
	class PickaxeError < StandardError; end
  
  autoload :Shell, 'pickaxe/shell'
  autoload :Color, 'pickaxe/color'
	autoload :Main, 'pickaxe/main'
	autoload :Test, 'pickaxe/test'
	autoload :Errors, 'pickaxe/errors'
end

require 'pickaxe/extensions'

