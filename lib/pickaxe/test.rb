module Pickaxe
	class TestLine < String
		attr_accessor :index
		def initialize(itself, index)
			super(itself)
			self.index = index + 1
		end
	end
		
	class Test
		include Pickaxe::Errors
		
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
			@files.inject(nil) do |last, file|				
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
								if last != file									
									$stderr.puts unless last.nil?
									$stderr.puts("#{file}:".color(:red))
									last = file
								end
								$stderr.puts(e.message.color(:red).word_wrap(:indent => 2))
							end
						end					
					end
					file
				end
			end
		end
		
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
		include Pickaxe::Errors
		
		RE = /^\s*(\d+)\.?\s*(.+)$/u
		
		def self.parse(file, answers)
			content = []
			until answers.first.nil? or Answer::RE.match(answers.first)
				content << answers.shift
			end
						
			raise MissingAnswers.new(file, answers.first.index) if content.blank?
			raise BadQuestion.new(content.first) unless m = RE.match(content.first)
			raise MissingAnswers.new(content.first) if answers.blank?
									
			answers = answers.inject([]) do |joined, line|
				if Answer::RE.match(line)
					joined << [line]
				else
					raise BadAnswer.new(line) unless Answer::LINE_RE.match(line)
					joined.last << line
				end
				joined
			end
			
			answers = answers.collect {|answer| Answer.parse(answer) }
			Question.new(file, m[1], content, answers).tap do |q|
				raise NoCorrectAnswer.new(q) if q.correct_answers.blank?				
				raise NotUniqueAnswerIndices.new(q) unless q.answer_indices.uniq!.nil?
				q.content = q.content.join(" ").gsub("\\n", "\n")
			end
		end
		
		def shuffled_answers
			if @shuffled_answers.nil?
				unless Main.options[:sorted_answers]
					@shuffled_answers = self.answers.shuffle
					answer_indices.sort.each_with_index do |index, order|
						@shuffled_answers[order].index = index
					end
				else
					@shuffled_answers = self.answers
				end
			end
			
			@shuffled_answers
		end
		
		def answered(indices)
			content = self.content.word_wrap(:indent => index.to_s.length+2)
			content + "\n\n" + self.shuffled_answers.collect do |answer|
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
		
		def answer_indices
			shuffled_answers.collect(&:index)
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
		
		def self.parse(lines)
			m = RE.match(lines.shift)
			Answer.new(m[4].strip + " " + lines.map(&:strip).join(" ").gsub("\\n", "\n"),
				m[3].strip, !m[1].nil?)
		end
		
		def to_s
			"(#{self.index}) #{self.content}".word_wrap(:indent => 7)
		end
	end
end
