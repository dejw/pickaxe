module Pickaxe

	class PathError < PickaxeError; status_code(1) ; end
	class MissingAnswers < PickaxeError; status_code(2) ; end
	class BadAnswer < PickaxeError; status_code(3) ; end
		
	#
	# Test is a file in which questions are separated by a blank line.
	# Each question has content (first line), and answers remaining lines.
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
		COMMENTS_RE = /^#.*|^\/\/.*/
				
		def initialize(options, *files)
			@options = options
			@files = files.collect do |file_or_directory|
				raise PathError, "file or directory '#{file_or_directory}' does not exist" unless File.exist?(file_or_directory)
				if File.file?(file_or_directory)
					file_or_directory
				else
					Dir.glob("#{file_or_directory}/*.#{@options[:extension] || "txt"}")
				end				
			end.flatten
			
			@questions = []
			@files.each do |file|
				File.open(file) do |f|
					lines = f.readlines.collect(&:strip)
					lines = lines.reject {|line| line =~ COMMENTS_RE }
					lines.split("").reject(&:blank?).each do |question|
						@questions.push(Question.parse(file, question))
					end
				end
			end
		end
		
		# Yields questions randomly
		def each(&block)
			shuffled_questions.each(&block)
		end
		
		def shuffled_questions
			questions = if @options[:sorted]
				@questions
			else
				@questions.shuffle			
			end
			
			@selected = if @options[:select]
				questions[0...(@options[:select])]
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
		
	class Question < Struct.new(:file, :content, :answers)
		def self.parse(file, answers)
			content = answers.shift
			raise MissingAnswers, "question '#{content.truncate(20)}' has no answers'" if answers.blank?
			Question.new(file, content, answers.collect {|answer| Answer.parse(answer) })
		end
		
		def answered(indices)
			"#{self.content.word_wrap}\n\n" + self.answers.collect do |answer|
				selected = indices.include?(answer.index)
				line = (selected ? ">> " : "   ") + answer.to_s
				unless indices.blank?
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
			given.sort == answers.select(&:correctness).collect(&:index).sort
		end
	end
	
	class Answer < Struct.new(:content, :index, :correctness)
		RE = /^\s*(>>)?(\?\?)?\s*\((\w+)\)\s*(.+)$/
		def self.parse(line)
			raise BadAnswer, "'#{line.truncate(20)}' does not look like answer" if (m = RE.match(line)).nil?
			Answer.new(m[m.size-1].strip, m[m.size-2].strip, m[1] == ">>")
		end
		
		def to_s
			"(#{self.index}) #{self.content}".word_wrap
		end
	end
end
