module Pickaxe 
  # Extracted from 
  # https://github.com/wycats/thor/blob/master/lib/thor/shell/color.rb
	module Color
		# Embed in a String to clear all previous ANSI sequences.
		CLEAR = "\e[0m"
		# The start of an ANSI bold sequence.
		BOLD = "\e[1m"

		# Set the terminal's foreground ANSI color to black.
		BLACK = "\e[30m"
		# Set the terminal's foreground ANSI color to red.
		RED = "\e[31m"
		# Set the terminal's foreground ANSI color to green.
		GREEN = "\e[32m"
		# Set the terminal's foreground ANSI color to yellow.
		YELLOW = "\e[33m"
		# Set the terminal's foreground ANSI color to blue.
		BLUE = "\e[34m"
		# Set the terminal's foreground ANSI color to magenta.
		MAGENTA = "\e[35m"
		# Set the terminal's foreground ANSI color to cyan.
		CYAN = "\e[36m"
		# Set the terminal's foreground ANSI color to white.
		WHITE = "\e[37m"

		# Set the terminal's background ANSI color to black.
		ON_BLACK = "\e[40m"
		# Set the terminal's background ANSI color to red.
		ON_RED = "\e[41m"
		# Set the terminal's background ANSI color to green.
		ON_GREEN = "\e[42m"
		# Set the terminal's background ANSI color to yellow.
		ON_YELLOW = "\e[43m"
		# Set the terminal's background ANSI color to blue.
		ON_BLUE = "\e[44m"
		# Set the terminal's background ANSI color to magenta.
		ON_MAGENTA = "\e[45m"
		# Set the terminal's background ANSI color to cyan.
		ON_CYAN = "\e[46m"
		# Set the terminal's background ANSI color to white.
		ON_WHITE = "\e[47m"

		# Set color by using a string or one of the defined constants. If a third
		# option is set to true, it also adds bold to the string. This is based
		# on Highline implementation and it automatically appends CLEAR to the end
		# of the returned String.
		#
		def self.set_color(string, color, bold=false)
			if Pickaxe::WINDOWS_IT_IS
				string
			elsif not (Main.options || {})[:no_colors]
				color = self.const_get(color.to_s.upcase) if color.is_a?(Symbol)
				bold = bold ? BOLD : ""
				"#{bold}#{color}#{string}#{CLEAR}"
			else
				"#{CLEAR}#{string}"
			end
		end
	end
end
