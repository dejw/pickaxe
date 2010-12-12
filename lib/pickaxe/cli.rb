require 'optparse'

parser = OptionParser.new do |opts|
  opts.banner = <<END_OF_BANNER
Usage: 
  #{$0.split("/").last} path [, path ...]
  
Uses given paths (files or directories) to generate a test from *.txt files.
END_OF_BANNER
  
  opts.separator ""
  opts.on("-e", "--ext [EXTENSION]", "Use files with given EXTENSION " +
  	"(default 'txt')") do |extension|
    Pickaxe::Main.options[:extension] = extension
  end
  
	opts.on("-s", "--sorted", "Do not shuffle questions") do |v|
		Pickaxe::Main.options[:sorted] = true
	end
	
	opts.on("--sorted-answers", "Do not shuffle answers") do |v|
		Pickaxe::Main.options[:sorted_answers] = true
	end	
	
	opts.on("--select [NUMBER]", "Select certain number of questions") do |v|
		Pickaxe::Main.options[:select] = Integer(v)
	end
	  
	opts.on("--single", "Generated test will have only 1 correct answer") do |v|
		Pickaxe::Main.options[:one_choice] = true
	end
	
	opts.on("--full-test", "Checks test after all questions are answered") do |v|
		Pickaxe::Main.options[:full_test] = true
	end
	
	opts.on("--repeat-incorrect", "Repeat questions answered incorrectly") do |v|
		Pickaxe::Main.options[:repeat_incorrect] = true
	end
	
	opts.on("--strict", "Quit on syntax error in test file") do |v|
		Pickaxe::Main.options[:strict] = true
	end
	
	opts.on_tail("--syntax-check", "Check syntax only - do not run test") do
    Pickaxe::Main.options[:syntax_check] = true
  end
  
	opts.on("--clear", "Turn on shell clearing before question") do |v|
		Pickaxe::Main.options[:clear] = true
	end	
	
	opts.on("--no-color", "Turn off colors") do |v|
		Pickaxe::Main.options[:no_colors] = true
	end	
  
  opts.on_tail("--version", "Show version") do
    puts "pickaxe version #{Pickaxe::VERSION}"
    exit
  end
  
	opts.on_tail("-h", "--help", "Show this message") do
		puts opts
		exit
	end
end

begin
	parser.parse!
	
	if Pickaxe::WINDOWS_IT_IS
		$stderr.puts <<END_OF_MESSAGE
! Hi there Windows user.

  You will not be able to see colors, all diacritics
  will be transliterated, dynamic console width
  is not available, You cannot answer using the [TAB]
  and the console will not be cleared on new question.
  
  Sorry for the inconvenience.
END_OF_MESSAGE
		
	end
	
	if Pickaxe::Main.options[:full_test] and Pickaxe::Main.options[:repeat_incorrect]
		$stderr.puts(("! --full-test disables the --repeat-incorrect option" ).color(:yellow))
		Pickaxe::Main.options[:repeat_incorrect] = false
	end
	
	if Pickaxe::Main.options[:one_choice] and Pickaxe::Main.options[:repeat_incorrect]
		$stderr.puts(("! --one-choice disables the --repeat-incorrect option" ).color(:yellow))
		Pickaxe::Main.options[:repeat_incorrect] = false
	end
	
	Pickaxe::Main.new(ARGV)
rescue Pickaxe::PickaxeError, OptionParser::InvalidOption => e
	$stderr.puts(("! " + e.to_s).color(:red))
end
