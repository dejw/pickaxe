module Pickaxe
	module Errors
		class PathError < PickaxeError
			def initialize(file_or_directory)
				super("file or directory '#{file_or_directory}' does not exist")
			end
		end
	
		class TestSyntaxError < PickaxeError
			def initialize(line, message)
				super("  line #{line}: #{message}")
			end
		end
	
		class MissingContent < TestSyntaxError
			def initialize(line)
				super(line, "no content (check blank lines nearby)")
			end	
		end
	
		class MissingAnswers < TestSyntaxError
			def initialize(question)
				super(question.index, 
					BadQuestion.message(question, "has no answers"))
			end
		end
	
		class BadAnswer < TestSyntaxError
			def initialize(line)
				super(line.index, 
					"'#{line.truncate(20)}' starts with weird characters")
			end
		end
	
		class BadQuestion < TestSyntaxError
			def self.message(question, m)
				"question '#{question.truncate(20)}' #{m}"
			end		
		
			def initialize(question)
				super(question.index, 
					"'#{question.truncate(20)}' does not look like question")
			end	
		end

		class NoCorrectAnswer < TestSyntaxError
			def initialize(question)
				super(question.content.first.index,
					BadQuestion.message(question.content.first, "has no correct answers"))
			end
		end
	
		class NotUniqueAnswerIndices < TestSyntaxError
			def initialize(question)
				super(question.content.first.index,
					BadQuestion.message(question.content.first, "answer indices are not unique"))
			end
		end
	end
end
