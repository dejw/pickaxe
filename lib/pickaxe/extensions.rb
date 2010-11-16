class String
	def word_wrap(*args)
		options = args.extract_options!
		unless args.blank?
			options[:line_width] = args[0] || 80
		end
		options.reverse_merge!(:line_width => 80)

		self.split("\n").collect do |line|
			line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
		end * "\n"
	end
end
