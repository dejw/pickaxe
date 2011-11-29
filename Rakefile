
require 'rake'

task :default => ["doc:gen"]

namespace :doc do
	task :gen do
		options = {
			:manual => "pickaxe manual",
			:style => ["80c", "toc"],
			
		}.collect do |k, a| 
			[a].flatten.collect {|v| "--#{k}=#{v.inspect}" }.join(" ")
		end.join(" ")
				
		ENV['RONN_LAYOUT'] = File.expand_path(File.join(File.dirname(__FILE__), "doc", "template", "github.html"))
		sh "ronn --html #{options} doc/pickaxe.1.ronn"
	end
end
