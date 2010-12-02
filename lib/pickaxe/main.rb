module Pickaxe
	class Main
		class NoTests < PickaxeError; status_code(1) ; end
		
		cattr_accessor :options
		
		END_OF_TEST_MESSAGE = <<END_OF_TEST
This is the end of this test and You can now jump back to
any question and check (or change) Your answers.

If You do not know how to jump back type `?' and press [ENTER].

Hit [ENTER] to rate the test and see Your incorrect answers.
END_OF_TEST

		def initialize(paths, options = {})
			raise NoTests, "no tests to run" if paths.empty?
			
			Main.options = options			
			@test = Test.new(*paths)
			return if options[:syntax_check]
			
			puts "! Hit Control-D to end test.\n\n"
			
			@logger = Logger.new(File.open('answers.log', File::WRONLY|File::TRUNC|File::CREAT))
			@logger.formatter = lambda { |severity, time, progname, msg| msg.to_s + "\n" }
			
			@questions = @test.shuffled_questions
			@questions_length = @questions.length.to_f
			@answers = Hash.new([])					
			@started_at = Time.now			
			@current_index = 0
			
			while @current_index < @questions.length + (Main.options[:full_test] ? 1 : 0) do
				@question = @questions[@current_index]
				
				unless @question.nil?
					puts "#{@current_index+1} / #{@questions.length}\t\tFrom: #{@question.file}\t\tTime spent: #{spent?}"
					puts @question.answered(@answers[@question])
				else
					puts END_OF_TEST_MESSAGE
				end
				
				until (line = prompt?).nil? or command(line)
					# empty
				end
															
				break if puts or line.nil?
			end
			
			statistics!
		end
		
		#
		# Available commands
		# 	@ question 		jumps to given question
		# 	<+						moves back one question
		# 	>+						moves forward one question
		# 	a [ b ...]    answers the question
		#   ?							shows help
		#
		def command(line)
			case line
			when /^\s*@\s*(.+)/	then # @ question
				@current_index = Integer($1) -1
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
				if Main.options[:full_test] and @question.nil?
					Main.options[:full_test] = false
					Main.options[:force_show_answers] = true
					
					@questions = @test.selected.select { |q| not q.correct?(@answers[q]) }
					@current_index = 0
				else				
					@current_index += 1
				end
				true
			when /\?/ then
				puts <<END_OF_HELP
				
Available commands (whitespace does not matter):
  @ question   jumps to given question
  <            moves back one question
  >            moves forward one question
  a [ b ...]   answers the question
  ?            shows help
  
END_OF_HELP
				false
			else
				@answers[@question] = line.strip.split(/\s+/).collect(&:strip)				
				puts @question.check?(@answers[@question]) unless Main.options[:full_test]
				@current_index += 1
				true
			end
		end
		
		def statistics!
			@stats = @test.statistics!(@answers)
						
			@answers.each do |question, answers|
				@logger << ("#{question.index}: #{answers.join(" ")}\n")
			end
				
			puts			
			puts "Time: #{spent?}"
			puts "All: #{@questions.length}"
			stat :correct, :green
			stat :unanswered, :yellow
			stat :incorrect, :red
		end
		
		def error(msg)
			$stderr.puts(("! " + msg).color(:red))
			false
		end
		
		def prompt?(p = "? ")
			print p
			$stdin.gets
		end
		
		def spent?
			(Time.now - @started_at).to_i.to_duration			
		end
	protected
		def stat(name, color)
			value = @stats[name.to_s.downcase.to_sym]
			puts format("#{name.to_s.capitalize}: #{value} (%g%%)", value/@questions_length * 100).color(color)
		end
	end
end
