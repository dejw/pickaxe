require "rubygems"
require "bundler"

Bundler.setup(:default)

require 'active_support/all'

module Pickaxe
	VERSION = "0.2.0"
	
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

