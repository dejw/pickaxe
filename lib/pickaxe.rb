require "rubygems"
require "bundler"

Bundler.setup(:default)

require 'active_support/all'

module Pickaxe
	VERSION = "0.1.2"
	
	class PickaxeError < StandardError
		attr_reader :status_code
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
end

# TODO: use autoload
require 'pickaxe/shell'
require 'pickaxe/extensions'
require 'pickaxe/main'
require 'pickaxe/test'

