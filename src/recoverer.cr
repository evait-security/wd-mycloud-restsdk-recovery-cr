require "dir"

module Recoverer
	extend self

	# Create output directory
	def createOutDir(output_dir)
		if Dir.exists?(output_dir)
      puts "[-] #{output_dir} already exists".colorize.red
      exit(1)
		else
			begin 
				Dir.mkdir_p(output_dir)
			rescue e 
		    puts "[-] Error creating #{output_dir}".colorize.red
        exit(1)
			end
		end
	end

	# Test if database is accessable
	def checkDB(database_index)
		begin 
			DB.open "sqlite3://#{database_index}" do |db|
					db.query "SELECT id FROM files LIMIT 1;"
			end
		rescue e 
			if e.message.as(String).includes?("malformed")
        puts "[-] The Database seems malformed, you can try to restore it with this program. Check out -h, --help for more information".colorize.red
        exit(1)
			else 
        puts "[-] Error while opening the database: #{e}".colorize.red
        exit(1)
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
      puts "[-] #{e}".colorize.red
      exit(1)
		end

		# Get all files entries where parentID is NOT set
		begin
			db_output = database.query("SELECT id, name, mimeType FROM files WHERE parentID is NULL")
			db_output.each do
				id, name, mimeType = db_output.read(String, String, String)
				files_structure.push(FileClass.new(id, name, mimeType))
			end
		rescue e
      puts "[-] Error reading the database: #{e}".colorize.red
      exit(1)
		end

		return files_structure
	end


	def buildTree(file_structure : Array, files_dir : String, output_dir : String)

		real_file_names = Dir.glob("#{files_dir}/**/*")
		folders = [] of FileClass
		files = [] of FileClass
		file_structure.each do |file|
			if file.mimeType == "application/x.wd.dir"
				folders.push(file)
			else
				real_file_names.each do |name|
					if name == file.contentID
						files.push(file)
					end
				end
			end
		end

		root_node = Node.new(FileClass.new(output_dir), [] of Node)
		root_node = tree_insert(folders, root_node)
		root_node = tree_insert(files, root_node)
		root_node.clean_dirs()

		return root_node
	end

	# Inserts a list of <FileClass> into the <Node>
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


	# Tries to rebuild file structure
	# raises Exception
	def recoverDB(database_index : String , files_dir : String, output_dir : String, quite : Bool)

		unless quite
			puts "[*] Using database: #{database_index}"
			puts "[*] Files directory path: #{files_dir}"
		end
    
    checkDB(database_index)
		
    begin 
			files_structure = getFilesFromDB(database_index)
      puts "[+] Found #{files_structure.size} database entries".colorize.green unless quite
		rescue e
			puts "[-] #{e}".colorize.red
      puts "[!] Try to use the --restore option".colorize.yellow
      exit(1)
		end

		root_node = buildTree(files_structure, files_dir, output_dir)
		root_node.create_dirs("", files_dir)

	end


	# Tries to restore the given database
	def restore(db_path : String , output_file : String, quite : Bool)

		puts "[*] Trying to restore the database file located at: #{db_path}" unless quite

		# If no output file given a default one will be selcted
		if output_file.empty?
			puts "[-] No output parameter given, using __restored.db" unless quite
			output_file = "__restored.db"
		else 
			puts "[*] Output file: #{output_file}" unless quite
		end

		if ! File.exists?(db_path)
      puts "[-] #{db_path} does not exist".colorize.red
      exit(1)
		end

		if File.exists?(output_file)
      puts "[-] #{output_file} already exists".colorize.red
      exit(1)
		end

		begin 			
			# IMMENSLY HIGH DANGER FOR INJECTIONS, ONLY INTENDED FOR PRIVATE USE
			`sqlite3 #{db_path} ".recover"  | sqlite3 #{output_file} 2>/dev/zero`
		rescue e
      puts "[-] There was a problem recovering the database:#{e}".colorize.red
      exit(1)
		end
	end
end
