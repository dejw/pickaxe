module Pickaxe
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
		
		class PathError < PickaxeError; status_code(1) ; end
		class MissingAnswers < PickaxeError; status_code(2) ; end
		class BadAnswer < PickaxeError; status_code(3) ; end
		
		def initialize(*files)
			options = files.extract_options!
			@files = files.collect do |file_or_directory|
				raise PathError, "file or directory '#{file_or_directory}' does not exist" unless File.exist?(file_or_directory)
				if File.file?(file_or_directory)
					file_or_directory
				else
					Dir.glob("#{file_or_directory}/*.#{options[:extension] || "txt"}")
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
			@questions.shuffle
		end
		
		def find(index)
			raise NotImplementedError
		end
	end
		
	class Question < Struct.new(:file, :content, :answers)
		def self.parse(file, answers)
			content = answers.shift
			raise MissingAnswers, "question '#{content.truncate(20)}' has no answers'" if answers.blank?
			Question.new(file, content, answers.collect {|answer| Answer.parse(answer) })
		end
		
		def header
			"File: #{file}"
		end
		
		def answered(indices)
			"#{self.content.word_wrap}\n\n" + self.answers.collect do |answer|
				if indices.include?(answer.index)
					"@ "
				else
					"  "
				end + answer.to_s
			end.join("\n") + "\n\n"
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