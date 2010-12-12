require "rubygems"
require "bundler/setup"
require "active_support/all"
require "rbconfig"
require "unidecoder"
begin
	require 'readline'
rescue LoadError
	class Readline
		def self.completion_proc=(value); end
		def self.readline(prompt)
			print prompt
			$stdin.gets
		end
	end
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

module Pickaxe
	VERSION = "0.6.2"
	
	class PickaxeError < StandardError; end
  
	WINDOWS_IT_IS = Config::CONFIG['host_os'] =~ /mswin|mingw/

	autoload :Shell, 'pickaxe/shell'
	autoload :Color, 'pickaxe/color'
	autoload :Main, 'pickaxe/main'
	autoload :Test, 'pickaxe/test'
	autoload :Errors, 'pickaxe/errors'
end

require 'pickaxe/extensions'

