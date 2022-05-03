require "dir"

module Recoverer
	extend self

	# Check if parameters are in place
	def check_paras(database_index, files_dir)
		error = "" 
		
		if database_index.empty?
			error = "Path to database missing (try -h for help)"
		end

		if files_dir.empty?
			error = "Path to files directory missing (try -h for help)"
		end

		if Dir.empty?(files_dir)
			error = "#{files_dir} is empty"
		end

		raise Exception.new(error) unless error.empty?
		return true
	end


	# Create output directory
	def createOutDir(output_dir)
		if Dir.exists?(output_dir)
			raise Exception.new("#{output_dir} already exists")
		else
			begin 
				Dir.mkdir_p(output_dir)
			rescue e 
				raise Exception.new("Error creating #{output_dir}")
			end
		end
	end


	# Test if database is accessable
	def checkDB(database_path)
		begin 
			DB.open "sqlite3://#{database_index}" do |db|
					db.query "SELECT id FROM files;"
			end
		rescue e 
			if e.message.as(String).includes?("malformed")
				raise Exception.new("The Database seems malformed, you can try to restore it with this program. Check out -h,--help for more information")
			else 
				raise e
			end
		end
	end


	# Get all file entries where the parentID is set (if no parentID is present its a directory in root)
	def getFilesFromDB(database_index)

		database = DB.open "sqlite3://#{database_index}"
		files_structure = [] of FileClass
		begin
			db_output = database.query("SELECT id, name, parentID, mimeType, contentID FROM files WHERE parentID not NULL")
			db_output.each do
				id, name, parentID, mimeType, contentID = db_output.read(String, String, String, String, String)
				files_structure.push(FileClass.new(id, name, parentID, mimeType, contentID))
			end
		rescue e
			raise Exception.new("Error reading database")
		end

		# Get all files entries where parentID is NOT set
		begin
			db_output = database.query("SELECT id, name, mimeType FROM files WHERE parentID is NULL")
			db_output.each do
				id, name, mimeType = db_output.read(String, String, String)
				files_structure.push(FileClass.new(id, name, mimeType))
			end
		rescue e
			raise Exception.new("Error reading database")
		end

		return files_structure
	end


	def buildTree(file_structure : Array, files_dir : String)
	
		real_file_names = Dir.entries(files_dir)
		folders = [] of FileClass
		files = [] of FileClass
		file_structure.each do |file|
			if file.mimeType == "application/x.wd.dir"
				folders.push(file)
			elsif real_file_names.bsearch { |x| x == file.contentID } != nil
				files.push(file)
			end
		end

		
		root_node = Node.new(FileClass.new(), [] of Node)
		root_node = tree_insert(folders, root_node)
		root_node = tree_insert(files, root_node)
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		root_node.clean_dirs()
		#root_node.clean_dirs()
		root_node.print(0)

	end


	def tree_insert(file_structure : Array, root_node : Node)

		total_count = file_structure.size	

		# Find root nodes
		file_structure.each_with_index do |file, i|
			if file.parentID == nil
				root_node.links.push(Node.new(file))	
			end
		end

		# Delete nodes
		root_node.links.each do |node|
			file_structure.delete(node.file)
		end

		found_count = 0
		del_list = [] of FileClass

		while true
			last_count = 0

			file_structure.each do |file|
				if root_node.insert(file)
					found_count += 1
					del_list.push(file)	
				end
			end

			# End if no new files have been found
			break if del_list.empty?
			del_list.each do |del_file|
				file_structure.delete(del_file)
			end
			del_list.clear
		end

		return root_node
	end

	# Tries to rebuild file Structure
	# raises Exception
	def recoverDB(database_index : String , files_dir : String, output_dir : String, quite : Bool)

		check_paras(database_index, files_dir)

		unless quite
			puts "[i] Starting recovery process"
			puts "[i] Opening database:\t #{database_index}"
			puts "[i] Files directory path:\t #{files_dir}"
		end

		if output_dir.empty?
			puts "[!] No output directory given using default" unless quite
			output_dir = "__out" 
		end

		begin 
			createOutDir(output_dir)
		rescue e
			raise e
		end 
		puts "[i] Output directory:\t #{output_dir}" unless quite

		begin 
			files_structure = getFilesFromDB(database_index)		
		rescue e
			raise e
		end 
		puts "[i] Found #{files_structure.size} database entries" unless quite

		root_node = buildTree(files_structure, files_dir)

	end


	# Tries to restore the given database
	def restore(db_path : String , output_file : String, quite : Bool)

		puts "Trying to restore the database file located at: #{db_path}" unless quite

		# If no output file given a default one will be selcted
		if output_file.empty?
			puts "No output parameter given, using __restored.db" unless quite
			output_file = "__restored.db"
		else 
			puts "Output file: #{output_file}" unless quite
		end

		if ! File.exists?(db_path)
			raise Exception.new("#{db_path} does not exist")
		end

		if File.exists?(output_file)
			raise Exception.new("#{output_file} already exists")
		end

		begin 			
			# IMMENSLY HIGH DANGER FOR INJECTIONS, ONLY INTENDED FOR PRIVATE USE
			`sqlite3 #{db_path} ".recover"  | sqlite3 #{output_file} 2>/dev/zero`
		rescue e
			raise Exception.new("There was a problem recovering the database.")
		end
	end
end
