require 'optparse'

options = { :extension => "txt" }
OptionParser.new do |opts|
  opts.banner = <<END_OF_BANNER
Usage: 
  #{$0.split("/").last} path [, path ...]
  
Uses given paths (files or directories) to generate a test from *.txt files.
END_OF_BANNER
  
  opts.separator ""
  opts.on("-e", "--ext [EXTENSION]", "Use files with given EXTENSION " +
  	"(default 'txt')") do |extension|
    options[:extension] = extension
  end
  
	opts.on("-s", "--sorted", "Do not shuffle questions") do |v|
		options[:sorted] = true
	end
	
	opts.on("--select [NUMBER]", "Select certain number of questions") do |v|
		options[:select] = Integer(v)
	end
	  
	opts.on("--full-test", "Checks test after all questions are answered") do |v|
		options[:full_test] = true
	end
	
	opts.on("--strict", "Quit on syntax error in test file") do |v|
		options[:strict] = true
	end
	
	opts.on_tail("--syntax-check", "Check syntax only - do not run test") do
    options[:syntax_check] = true
  end
  
  opts.on_tail("--version", "Show version") do
    puts "pickaxe version #{Pickaxe::VERSION}"
    exit
  end
  
	opts.on_tail("-h", "--help", "Show this message") do
		puts opts
		exit
	end
end.parse!

begin
	Pickaxe::Main.new(ARGV, options)
rescue Pickaxe::PickaxeError => e
	$stderr.puts(("! " + e.message).color(:red))
	exit(e.status_code)
end
