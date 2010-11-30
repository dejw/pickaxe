module Pickaxe

	class PathError < PickaxeError; status_code(1) ; end
	
	class TestSyntaxError < PickaxeError; status_code(2) ; end
	class MissingAnswers < TestSyntaxError; status_code(2) ; end
	class BadAnswer < TestSyntaxError; status_code(3) ; end
	class BadQuestion < TestSyntaxError; status_code(4) ; end
	class NoCorrectAnswer < TestSyntaxError; status_code(3) ; end
		
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
				raise PathError, "file or directory '#{file_or_directory}' does not exist" unless File.exist?(file_or_directory)
				if File.file?(file_or_directory)
					file_or_directory
				else
					Dir.glob("#{file_or_directory}/*.#{Main.options[:extension] || "txt"}")
				end				
			end.flatten.collect { |f| f.squeeze('/') }
			
			@questions = []
			@files.each do |file|
				File.open(file) do |f|
					lines = f.readlines.collect(&:strip).enum_with_index.collect do |line, index|
						TestLine.new(line, index)
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
		RE = /^\s*(\d+)\.?\s*(.+)$/
		
		def self.parse(file, answers)
			content = []
			until answers.first.nil? or Answer::RE.match(answers.first)
				content << answers.shift
			end
			
			raise MissingAnswers, "#{file}: line #{answers.first.index}: no content (check blank lines nearby)" if content.blank?			
			raise BadQuestion, "#{file}: line #{content.first.index}: '#{content.first.truncate(20)}' does not look like question" unless m = RE.match(content.first)
									
			error_template = "#{file}: line #{content.first.index}: question '#{content.first.truncate(20)}' %s"
			raise MissingAnswers, (error_template % "has no answers") if answers.blank?
			
			answers = answers.inject([]) do |joined, line|
				if Answer::RE.match(line)
					joined << [line]
				else
					raise BadAnswer, "#{file}: line #{line.index}: '#{line.truncate(20)}' starts with weird characters" unless Answer::LINE_RE.match(line)
					joined.last << line
				end
				joined
			end
			
			Question.new(file, m[1], content, answers.collect {|answer| Answer.parse(file, answer) }).tap do |q|
				raise NoCorrectAnswer, (error_template % "has no correct answer") if q.correct_answers.blank?
			end
		end
		
		def answered(indices)
			content = self.content.collect(&:word_wrap).join("\n")
			"#{content}\n\n" + self.answers.collect do |answer|
				selected = indices.include?(answer.index)
				line = (selected ? ">> " : "   ") + answer.to_s
				
				if Main.options[:force_show_answers] or (not indices.blank? and not Main.options[:full_test]) then
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
		RE = /^\s*(>>)?\s*(\?\?)?\s*\((\w+)\)\s*(.+)$/
		LINE_RE = /^\s*(\w+)/
		
		def self.parse(file, lines)
			m = RE.match(lines.shift)
			Answer.new(m[m.size-1].strip + " " + lines.collect(&:strip).join(" "), m[m.size-2].strip, m[1] == ">>")
		end
		
		def to_s
			"(#{self.index}) #{self.content}".word_wrap
		end
	end
end
