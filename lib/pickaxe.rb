require "rubygems"
require "bundler"

Bundler.setup(:default)

require 'active_support/all'

module Pickaxe
	VERSION = "0.0.1"
	
	class PickaxeError < StandardError
		attr_reader :status_code
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
  
  module Shell
  	def self.dynamic_width
      (dynamic_width_stty.nonzero? || dynamic_width_tput)
    end

    def self.dynamic_width_stty
      %x{stty size 2>/dev/null}.split[1].to_i
    end

    def self.dynamic_width_tput
      %x{tput cols 2>/dev/null}.to_i
    end  
  end
end

# TODO: use autoload
require 'pickaxe/extensions'
require 'pickaxe/main'
require 'pickaxe/test'

