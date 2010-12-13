# -*- coding: UTF-8 -*-

module Pickaxe
	class TestLine < String
		attr_accessor :index
		def initialize(itself, index)			
			self.index = index + 1
			if Pickaxe::WINDOWS_IT_IS
				replace(itself.to_ascii)
			else
				replace(itself)
			end
		end
	end
		
	class Test		
		include Pickaxe::Errors
		
		attr_reader :questions
		
		include Enumerable
		
		# Ruby-comments and C-comments
		COMMENTS_RE = /^\s*(#|\/\/|;).*/
		
		def initialize(*files)
			@files = files.collect do |file_or_directory|
				unless File.exist?(file_or_directory)
					raise PathError.new(file_or_directory) 
				end
				
				if File.file?(file_or_directory)
					file_or_directory
				else
					Dir.glob("#{file_or_directory.gsub("\\", "/")}/*.#{Main.options[:extension]}")
				end				
			end.flatten.collect { |f| f.squeeze('/') }
			
			@questions = []
			@files.inject(nil) do |last, file|				
				File.open(file, "r:UTF-8") do |f|
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
		
		def each(options = Main.options, &block)
			shuffled_questions(options).each(&block)
		end
		
		def shuffled_questions(options = Main.options)
			questions = if options[:sorted]
				@questions
			else
				@questions.shuffle			
			end
			
			@selected = if options[:select]
				questions[0...(options[:select])]
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
		
		def initialize(*args)
			super(*args)
			reindex_answers(self.answers)
		end
		
		def self.parse(file, answers)
			content = []
			until answers.first.nil? or Answer::RE.match(answers.first)
				content << answers.shift
			end
						
			raise MissingContent.new(answers.first.index) if content.blank?
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
				q.content = q.content.join(" ").gsub("\\n", "\n")
			end
		end
		
		def reset!
			@shuffled_answers = nil
		end
		
		def shuffled_answers
			if @shuffled_answers.nil?
				unless Main.options[:sorted_answers]
					@shuffled_answers = self.answers.shuffle
					reindex_answers(@shuffled_answers)
				else
					@shuffled_answers = self.answers
				end
				
				if Main.options[:one_choice]
					# NOTE:
					# This hack line removes possible answers that states that non of
					# other answers are correct (in Polish), because this invalidates
					# the algorithm fot generating fourth answer from given 3
					#
					# NOTE: Other languages will remain untouched.
					#
					@shuffled_answers.reject! { |a| a.content =~ /(\s+|^)(ż|Ż)ad(na|ne|en)(\s+|$)/ui }
					reindex_answers(@shuffled_answers)
					# END OF HACK
			
					@shuffled_answers = generate_fourth_answer(@shuffled_answers[0...3])
				end
			end
			
			@shuffled_answers
		end
		
		def reindex_answers(answers)
			letters = ('a'...'z').to_a
			answers.each_with_index do |index, order|
				answers[order].index = letters[order]
			end
		end
		
		def generate_fourth_answer(answers)			
			correct = correct_answers(answers)
			answers << case correct.length
			when 0 then
				Answer.new(Answer::EMPTY, "d", true)
			when 1
				indices = answer_indices(answers)
				fourth = [[]]
				fourth.push(*indices.combination(2).to_a)
				fourth.push(*indices.combination(3).to_a)
				
				fourth = fourth.shuffle.first
				fourth = if fourth.empty?
					Answer::EMPTY
				else
					Answer::CORRECT_ARE % fourth.map(&:upcase).join(", ")
				end
				Answer.new(fourth, "d", false)
			else
				answers.each {|a| a.correctness = false }
				Answer.new(Answer::CORRECT_ARE % correct.map(&:upcase).join(", "), "d", true)
			end
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
		
		def correct_answers(a = shuffled_answers)
			a.select(&:correctness).collect(&:index).sort
		end
		
		def answer_indices(a = shuffled_answers)
			a.collect(&:index)
		end
		
		def check?(given)
			if correct?(given)
				"Correct!".color(:green)
			else
				missed = (correct_answers - given)
				missed =  unless missed.empty?
					"Missed: #{missed.join}".color(:yellow)
				else
					""
				end
				incorrect = (given - correct_answers)
				incorrect = unless incorrect.empty?
					"Wrong: #{incorrect.join}".color(:red)
				else
					""
				end
				"Incorrect, should be:".color(:red) + " #{correct_answers.join.color(:green)}! #{[missed, incorrect].join(" ")}" 
			end
		end
	end
	
	class Answer < Struct.new(:content, :index, :correctness)
		EMPTY = "None of answers above is correct"
		CORRECT_ARE = "Correct answers: %s"
		
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
