module Pickaxe
	module Shell
		# Extracted from 
		# https://github.com/wycats/thor/blob/master/lib/thor/shell/basic.rb
		#
		# This is turned off on Windows and returns always 80
		def self.dynamic_width
			if Pickaxe::WINDOWS_IT_IS
				80
			else
				(dynamic_width_stty.nonzero? || dynamic_width_tput)
			end
		end
		
		def self.clear
			if not Pickaxe::WINDOWS_IT_IS and Main.options[:clear]
				print "\e[H\e[2J"
			end
		end
		
	private
		def self.dynamic_width_stty
		  %x{stty size 2>/dev/null}.split[1].to_i
		end

		def self.dynamic_width_tput
		  %x{tput cols 2>/dev/null}.to_i
		end  
	end
end
