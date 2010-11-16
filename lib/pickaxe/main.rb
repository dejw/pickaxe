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
				
				puts "#{@question.header(@current_index)}\n"
				puts @question.answered(@answers[@question])
				
				until (line = prompt?).nil? or command(line)
					# empty
				end
											
				break if puts or line.nil?
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
		#   ?							shows help
		#
		def command(line)
			case line
			when /^\s*@\s*(.+)/	then # @ question
				@current_index = Integer($1)
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
			when /^\s*!\s*(.+)/ then
				raise NotImplementedError
			when /\?/ then
				puts <<END_OF_HELP
				
Available commands (whitespace does not matter):
  @ question   jumps to given question
  <            moves back one question
  >            moves forward one question
    a [ b ...] answers the question  
  ! a [ b ...] answers the question and forces reveal correct answers
  ?            shows help
  
END_OF_HELP
				false
			else
				@answers[@question] = line.split(/\s+/).collect(&:strip)
				@current_index += 1
				true
			end
		end
		
		def statistics!
			stats = @test.statistics!(@answers)
			puts
			puts "All: #{@questions.length}"
			puts "Correct: #{stats[:correct]}".color(:green)
			puts "Unanswered: #{stats[:unanswered]}".color(:yellow)
			puts "Incorrect: #{stats[:incorrect]}".color(:red)
		end
		
		def error(msg)
			$stderr.puts(("! " + msg).color(:red))
			false
		end
		
		def prompt?(p = "? ")
			print p
			$stdin.gets
		end
	end
end
