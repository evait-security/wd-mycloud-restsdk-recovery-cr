require "./FileClass"

class Node

	property file 
	property links

	def initialize(@file : FileClass)
		@links = [] of Node
	end

	def initialize(@file : FileClass, links : Array)
		@links = [] of Node
	end
	
	def insert(file : FileClass)
		if file.parentID == @file.id
			@links.push(Node.new(file))
			return true
		elsif links.empty?
			return false
		else 
			links.each do |link|
				return true if link.insert(file)
			end
			return false
		end
	end


	def search(name : String) : String
		if @file.name == name
			return @name
		else 
			links.each do |link|
				val = link.search(name)
				if ! val.empty
					return "#{@name}" + "/" + val
				end
			end
		end
	end

end 
