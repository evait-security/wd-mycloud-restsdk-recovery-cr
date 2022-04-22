require "./FileClass"

class Node

	property name 
	property isDir
	property links
	property file 

	def initialize(@name : String, isDir : Bool)
		@links = [] of Node
	end

	def initialize(@name : String, isDir : Bool, links : Array)
		@links = [] of Node
	end
	
	def insert(file : FileClass)
		if file.parentFolderName == name
			@file = file	
			return true
		elsif links.empty?
			return false
		else 
			links.each do |link|
				return link.insert(file)
			end
		end
	end


	def search(name : String) : String
		if @name == name
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
