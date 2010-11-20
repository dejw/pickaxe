require "rubygems"
require "bundler/setup"
require "active_support/all"

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

module Pickaxe
	VERSION = "0.3.2"
	
	class PickaxeError < StandardError
		attr_reader :status_code
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
  
  autoload :Shell, 'pickaxe/shell'
  autoload :Color, 'pickaxe/color'
	autoload :Main, 'pickaxe/main'
	autoload :Test, 'pickaxe/test'
end

require 'pickaxe/extensions'

