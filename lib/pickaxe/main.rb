module Pickaxe
	class Main
		def initialize(paths, options = {})
			raise ArgumentError, "no tests to run" if paths.empty?
			@test = Test.new(*paths)			
			@questions = @test.shuffled_questions
			@answers = Hash.new([])
			
			@current_index = 0
			while @current_index < @questions.length do
				@question = @questions[@current_index]
				
				puts "#{@question.header}\n"
				puts @question.answered(@answers[@question])
				
				until (line = prompt?).nil? or command(line)
					# empty
				end
				$stdout.puts
				break if line.nil?
			end
			
			statistics!
		end
		
		#
		# Available commands
		# 	^ question 		jumps to given question
		# 	<+						moves back one question
		# 	>+						moves forward one question
		# 	! a [ b ...]  answers the question and forces to show correct answers
		# 	a [ b ...]    answers the question
		#
		def command(line)
			case line
			when /^\s*@\s*(.*)/	then # @ question
				@current_index = @questions.index(@test.find($1))
				true
			when /<+/ then
				if @current_index > 0
					@current_index -= 1 
					true
				else
					error "You are at first question"
				end
			when />+/ then
				if @current_index < (@questions.length - 1)
					@current_index += 1
					true
				else
					error "You are at last question"
				end
			when "\n" then
				@current_index += 1
				true
			when /^\s*!\s*(.*)/ then
				raise NotImplementedError
			else
				@answers[@question] = line.split(/\s+/).collect(&:strip)
				@current_index += 1
				true
			end
		end
		
		def statistics!
			puts "Bye!"
		end
		
		def error(msg)
			$stderr.puts("! " + msg)
			false
		end
		
		def prompt?(p = "? ")
			print p
			$stdin.gets
		end
	end
end
