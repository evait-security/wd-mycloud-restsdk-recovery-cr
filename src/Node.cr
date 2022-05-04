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

	def clean_dirs()
		delete_list = [] of Node
		if @file.mimeType == "application/x.wd.dir"
			if @links.empty?
				return true
			else 
				@links.each do |link|
					if link.clean_dirs()
						delete_list.push(link)
					end
				end
				delete_list.each do |delete|
					@links.delete(delete)
				end
				return true if @links.empty?
			end
		end
	end

	def print(depth : Int32)
		del = "  "

		if @file.mimeType == "application/x.wd.dir"
			puts "#{del * depth}(#{depth})Folder Name: #{@file.name}"
			@links.each do |link|
				link.print(depth + 1)
			end
		else 
			puts "#{"XX" * depth}(#{depth})File Name: #{@file.name}"
		end

	end


	def count()
		count = 0 
		if @links.empty?
			return 1
		else
			@links.each do |link|
				count += link.count
			end
		end
		return count
	end

end 
