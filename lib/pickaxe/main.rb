module Pickaxe
	class Main
		class NoTests < PickaxeError; end
		class TabTermination < PickaxeError; end
		
		cattr_accessor :options
		
		END_OF_TEST_MESSAGE = <<END_OF_TEST
This is the end of this test and You can now jump back to
any question and check (or change) Your answers.

If You do not know how to jump back type `?' and press [ENTER].

Hit [ENTER] to rate the test and see Your incorrect answers.
END_OF_TEST

		def initialize(paths, options = {})
			raise NoTests, "no tests to run" if paths.empty?
			
			@test = Test.new(*paths)
			return if options[:syntax_check]
						
			@logger = Logger.new(File.open('answers.log', 
				File::WRONLY|File::APPEND|File::CREAT))
			@logger.formatter = lambda { |s, t, p, msg| msg.to_s + "\n" }
			
			@questions = @test.shuffled_questions
			@answers = Hash.new([])					
			@started_at = Time.now			
			@current_index = 0

			if @questions_length == 0
				$stderr.puts "! No questions in test!".color(:red)
				return
			end
			
			begin
				if Pickaxe::WINDOWS_IT_IS
					puts "! Hit Control-Z + [Enter] to end test\n\n"
				else
					puts "! Hit Control-D or Control-C to end test.\n\n".color(:green)	
				end
				
				Readline.completion_proc = Proc.new do |line|
					@line = line
					raise TabTermination
				end

				while @current_index < @questions.length + (Main.options[:full_test] ? 1 : 0) do
					@question = @questions[@current_index]
				
					unless @question.nil?
						Shell.clear
						
						puts "#{@last_answer}\n\n"
						print "#{@current_index+1} / #{@questions.length}\t\t"
						puts "From: #{@question.file}\t\tTime spent: #{spent?}\n\n"
					
						puts @question.answered(@answers[@question])
					else
						puts END_OF_TEST_MESSAGE
					end
					
					until (line = prompt?).nil? or command(line)
						# empty
					end															
					break if puts or line.nil?
				end
			rescue Interrupt
				# empty
			ensure
				puts "#{@last_answer}\n\n"
				statistics!
			end
		end
		
		#
		# Available commands
		# 	@ question 		jumps to given question
		# 	<+						moves back one question
		# 	>+						moves forward one question
		# 	a [ b ...]    answers the question
		#   .             shows current question again
		#   ?							shows help
		#
		def command(line)
			@last_answer = nil
			
			case line.strip
			when /^\s*@\s*(.+)/	then # @ question
				@current_index = Integer($1) -1
				true
			when /\./ then
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
			when "" then
				if Main.options[:full_test] and @question.nil?
					Main.options[:full_test] = false
					Main.options[:force_show_answers] = true
					@questions_length ||= @questions.length.to_f
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
  .            shows current question again
  ?            shows help
  
END_OF_HELP
				false
			else
				@answers[@question] = convert_answers(line)
				unless Main.options[:full_test]
					@last_answer = @question.check?(@answers[@question])
					if Main.options[:repeat_incorrect] and not @question.correct?(@answers[@question])
						@answers.delete(@question)
						@questions.insert(@current_index + 1 + rand(@questions.length - @current_index), @question)
						@questions.delete_at(@current_index)
						@question.reset!
					else
						@current_index += 1
					end
				else
					@current_index += 1
				end				
				true
			end
		end
		
		ANSWER_CONVERTION_HASH = ('a'..'z').to_a[0,10].each_with_index.inject({}) do |m, p| 
			m[((p.last + 1) % 10).to_s] =  p.first
			m
		end
		
		def convert_answers(line)			
			line.gsub(/\s+/, "").downcase.each_char.collect do |c|
				ANSWER_CONVERTION_HASH[c] || c
			end.to_a.uniq
		end
		
		def statistics!
			@questions_length ||= @questions.length.to_f
						
			puts			
			puts "Time: #{spent?}"
			unless Main.options[:repeat_incorrect]
				@stats = @test.statistics!(@answers)

				
				puts "All: #{@questions.length}"
				stat :correct, :green
				stat :unanswered, :yellow
				stat :incorrect, :red
				
				@questions_length ||= @questions.length.to_f
				@answers.each do |question, answers|
					@logger << "!" unless question.correct?(answers)
					@logger << ("#{question.index}: #{answers.join(" ")}\n")
				end
				@logger << "\n"
			end				
		end
		
		def error(msg)
			$stderr.puts(("! " + msg).color(:red))
			false
		end
		
		def prompt?(p = "? ")
			unless Pickaxe::WINDOWS_IT_IS
			begin
				Readline.readline(p)
			rescue TabTermination
				puts
				@line + "\n"
			end else
				print p
				$stdin.gets
			end
		end
		
		def spent?
			(Time.now - @started_at).to_i.to_duration			
		end
	protected
		def stat(name, color)
			value = @stats[name.to_s.downcase.to_sym]
			puts format("#{name.to_s.capitalize}: #{value} (%g%%)", 
				value/@questions_length * 100).color(color)
		end
	end
end
