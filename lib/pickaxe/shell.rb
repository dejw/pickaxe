module Pickaxe
	module Shell
		# Extracted from 
		# https://github.com/wycats/thor/blob/master/lib/thor/shell/basic.rb
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
