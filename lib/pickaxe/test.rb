module Pickaxe

	class PathError < PickaxeError
		def initialize(file_or_directory)
			super("file or directory '#{file_or_directory}' does not exist")
		end
	end
	
	class TestSyntaxError < PickaxeError
		def initialize(file, line, message)
			super("#{file}: line #{line}: #{message}")
		end
	end
	
	class MissingContent < TestSyntaxError
		def initialize(file, line)
			super(file, line, "no content (check blank lines nearby)")
		end	
	end
	
	class MissingAnswers < TestSyntaxError
		def initialize(file, question)
			super(file, question.index, 
				BadQuestion.message(question, "has no answers"))
		end
	end
	
	class BadAnswer < TestSyntaxError
		def initialize(file, line)
			super(file, line.index, 
				"'#{line.truncate(20)}' starts with weird characters")
		end
	end
	
	class BadQuestion < TestSyntaxError
		def self.message(question, m)
			"question '#{question.truncate(20)}' #{m}"
		end		
		
		def initialize(file, question)
			super(file, question.index, 
				"'#{question.truncate(20)}' does not look like question")
		end	
	end
	
	class NoCorrectAnswer < TestSyntaxError
		def initialize(file, question)
			super(file, question.content.first.index,
				BadQuestion.message(question.content.first, "has no correct answers"))
		end
	end
		
	class TestLine < String
		attr_accessor :index
		def initialize(itself, index)
			super(itself)
			self.index = index + 1
		end
	end
		
	#
	# Test is a file in which questions are separated by a blank line.
	# Each question has content (lines until answer), and answers.
	# Answers are listed one per line which starts with optional >> (means answer
	# is correct), followed by index in parenthesis (index) and followed by text.
	#
	# Example:
	#
	#  1. To be or not to be?
	#  (a) To be.
	#  (b) Not to be.
	#  >> (c) I do not know.
	#
	class Test
		attr_reader :questions
		
		include Enumerable
		
		# Ruby-comments and C-comments
		COMMENTS_RE = /^\s*#.*|^\/\/.*/
		
		def initialize(*files)
			@files = files.collect do |file_or_directory|
				unless File.exist?(file_or_directory)
					raise PathError.new(file_or_directory) 
				end
				
				if File.file?(file_or_directory)
					file_or_directory
				else
					Dir.glob("#{file_or_directory}/*.#{Main.options[:extension]}")
				end				
			end.flatten.collect { |f| f.squeeze('/') }
			
			@questions = []
			@files.each do |file|
				File.open(file) do |f|
					lines = f.readlines.collect(&:strip).each_with_index.collect do |l, i|
						TestLine.new(l, i)
					end
					
					lines = lines.reject {|line| line =~ COMMENTS_RE }
					lines.split("").reject(&:blank?).each do |question|
						begin
							@questions.push(Question.parse(file, question))
						rescue TestSyntaxError => e
							if Main.options[:strict]						
								raise e 
							else
								$stderr.puts(e.message.color(:red))
							end
						end					
					end
				end
			end
		end
		
		# Yields questions randomly
		def each(&block)
			shuffled_questions.each(&block)
		end
		
		def shuffled_questions
			questions = if Main.options[:sorted]
				@questions
			else
				@questions.shuffle			
			end
			
			@selected = if Main.options[:select]
				questions[0...(Main.options[:select])]
			else
				questions
			end			
		end
		
		def selected
			@selected ||= @questions
		end
		
		def statistics!(answers)
			Hash.new(0).tap do |statistics|
				selected.each do |question|
					given = answers[question]
					if question.correct?(given)
						statistics[:correct] += 1
					elsif given.blank?
						statistics[:unanswered] += 1
					else
						statistics[:incorrect] += 1
					end
				end
			end
		end
	end
		
	class Question < Struct.new(:file, :index, :content, :answers)
		RE = /^\s*(\d+)\.?\s*(.+)$/u
		
		def self.parse(file, answers)
			content = []
			until answers.first.nil? or Answer::RE.match(answers.first)
				content << answers.shift
			end
						
			raise MissingAnswers.new(file, answers.first.index) if content.blank?			
			unless m = RE.match(content.first)
				raise BadQuestion.new(file, content.first) 
			end
			raise MissingAnswers.new(file, content.first) if answers.blank?
									
			answers = answers.inject([]) do |joined, line|
				if Answer::RE.match(line)
					joined << [line]
				else
					raise BadAnswer.new(file, line) unless Answer::LINE_RE.match(line)
					joined.last << line
				end
				joined
			end
			
			answers = answers.collect {|answer| Answer.parse(file, answer) }
			Question.new(file, m[1], content, answers).tap do |q|
				raise NoCorrectAnswer.new(file, q) if q.correct_answers.blank?
				q.content = q.content.join(" ").gsub("\\n", "\n")
			end
		end
		
		def answered(indices)
			content = self.content.word_wrap(:indent => index.to_s.length+2)
			content + "\n\n" + self.answers.collect do |answer|
				selected = indices.include?(answer.index)
				line = (selected ? ">> " : "   ") + answer.to_s
				
				if(Main.options[:force_show_answers] or
					(not indices.blank? and not Main.options[:full_test])) then
					if selected and answer.correctness
						line.color(:green)
					elsif not selected and answer.correctness
						line.color(:yellow)
					elsif selected and not answer.correctness
						line.color(:red)
					end
				end || line				
			end.join("\n") + "\n\n"
		end
		
		def correct?(given)
			given.sort == correct_answers
		end
		
		def correct_answers
			answers.select(&:correctness).collect(&:index).sort
		end
		
		def check?(given)
			if correct?(given)
				"Correct!".color(:green)
			else
				"Incorrect! Correct was: #{correct_answers.join(", ")}".color(:red)
			end
		end
	end
	
	class Answer < Struct.new(:content, :index, :correctness)
		RE = /^\s*(>+)?\s*(\?+)?\s*\(?(\w)\)\s*(.+)$/u
		LINE_RE = /^\s*\\?\s*([[:alpha:]]|\w+)/u
		
		def self.parse(file, lines)
			m = RE.match(lines.shift)
			Answer.new(m[4].strip + " " + lines.map(&:strip).join(" ").gsub("\\n", "\n"),
				m[3].strip, !m[1].nil?)
		end
		
		def to_s
			"(#{self.index}) #{self.content}".word_wrap(:indent => 7)
		end
	end
end
