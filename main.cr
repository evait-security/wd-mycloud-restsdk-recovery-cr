require "option_parser"
require "sqlite3"
require "db"
require "kernel"
require "file"
require "dir"
require "io"

ERROR = "[-] ERROR:"
INFO = "[i] Info:"

database_index = ""
backup_db = ""
files_dir = ""
output_dir = ""

action = ""

##### Statistics #####
files_found = 0
root_folders = 0 
folders = 0 


OptionParser.parse do |parser|
	parser.banner = "WD MyCloud rest-sdk recovery"

	parser.on("-d DATABASE", "--database=DATABASE", "Path to the index.db file") {|_DATABASE| database_index = _DATABASE }
	parser.on("-f FILES_DIR", "--files=FILES_DIR", "Path to the directory containing the unorganized files") {|_FILES_DIR| files_dir = _FILES_DIR }
	parser.on("-o OUT_DIR", "--output=OUT_DIR", "(optional) Path to the directory where the directory structure should be created ") {|_OUT_DIR| output_dir = _OUT_DIR }
	parser.on("-r", "--restore", "Tries to restore the given database, uses -o for output(dir|name)") {action = "restore"}

	parser.on "-h", "--help", "Show help" do 
		puts parser 
		exit 
	end

	parser.invalid_option do |flag|
		STDERR.puts "#{ERROR} #{flag} is not a valid option."
		exit(1)
	end
end


if action == "restore"
	restore(database_index, output_dir)
	exit 0
end


error=false
if database_index.empty?
	STDERR.puts "#{ERROR} Path to database missing (try -h for help)"
	error = true
end

if files_dir.empty?
	STDERR.puts "#{ERROR} Path to files direcotry missing (try -h for help)"
	error = true
end

exit 1 if error

# Test if database is accessable
begin 
	DB.open "sqlite3://#{database_index}" do |db|
			db.query "SELECT id FROM files;"
	end
rescue e 
	if e.message.as(String).includes?("malformed")
		STDERR.puts "#{ERROR} The Database seems malformed, you can try to restore it with this program. Check out -h,--help for more information"
		exit 1
	end
end


puts "#{INFO} Starting recovery process"
puts "#{INFO} Opening database:\t #{database_index}"
puts "#{INFO} Files directory path:\t #{files_dir}"

if output_dir.empty?
	puts "#{INFO} No output directory given using default"
	output_dir = "__out" 
end


puts "#{INFO} Output directory:\t #{output_dir}"


# Get all file entries where the parentID is set (if no parentID is present its a directory in root)
database = DB.open "sqlite3://#{database_index}"
files_structure = [] of FileClass
begin
	db_output = database.query("SELECT id, name, parentID, mimeType, contentID FROM files WHERE parentID not NULL")
	db_output.each do
		id, name, parentID, mimeType, contentID = db_output.read(String, String, String, String, String)
		files_structure.push(FileClass.new(id, name, parentID, mimeType, contentID))
		files_found += 1
	end
rescue e
	puts "#{ERROR} Database could not be queried: #{e}"	
end

# Get all files entries where parentID is NOT set
begin
	db_output = database.query("SELECT id, name, mimeType FROM files WHERE parentID is NULL")
	db_output.each do
		id, name, mimeType = db_output.read(String, String, String)
		files_structure.push(FileClass.new(id, name, mimeType))
		root_folders += 1
	end
rescue e
	puts "#{ERROR} Database could not be queried: #{e}"	
	exit 1
end

total_files = files_found + root_folders
puts "#{INFO} Found #{total_files} database entries"

# Create output directory
if Dir.exists?(output_dir)
	STDERR.puts "#{ERROR} #{output_dir} already exists"
	exit 1
else
	begin 
		Dir.mkdir_p(output_dir)
	rescue e 
		puts e
	end
end

root_node = Node.new("_ROOT_", true, [] of Node)

# Get list of uniq folders
folder_count = 0
files_structure.each do |file|
	if file.parentID == nil && file.mimeType == "application/x.wd.dir"
		root_node.links.push(Node.new(file.name, true, ))	
	elsif file.mimeType == "application/x.wd.dir"
		folder_count += 1	
	end
end

# Insert actual parentFolderName into file class
files_structure.each do |file_orig|
	files_structure.each do |file_copy|
		if file_orig.parentID == file_copy.id
			file_orig.parentFolderName = file_copy.name
			break
		end
	end
end


files_orig_size = files_structure.size

while (files_orig_size - folder_count) <= files_structure.size
	files_structure.each do |file|
		if root_node.insert(file)
			files_structure.reject(file)
		end
	end
end

############ Functions

# Tries to restore the given database
def restore(db_path, output_file)

	puts "Trying to restore the database file located at: #{db_path}"

	# If no output file given a default one will be selcted
	if output_file.empty?
		puts "No output parameter given, using __restored.db"
		output_file = "__restored.db"
	else 
		puts "Output file: #{output_file}"
	end

	if File.exists?(output_file)
		STDERR.puts "#{ERROR} File #{output_file} does already exist"
		exit 1
	end

	begin 			
		# IMMENSLY HIGH DANGER FOR INJECTIONS, ONLY INTENDED FOR PRIVATE USE
		`sqlite3 #{db_path} ".recover" 2>/dev/zero | sqlite3 #{output_file} 2>/dev/zero`
	rescue e
		STDERR.puts "#{ERROR} There was a problem recovering the database."
		exit 1
	end
end


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



class FileClass

	property id
	property name
	property mimeType
	property contentID
	property parentID
	property parentFolderName 

	def initialize(@id : String, @name : String, @parentID : String, @mimeType : String, @contentID : String)
		@parentFolderName = ""
	end

	def initialize(@id : String, @name : String, @mimeType : String)
		@parentID = nil
		@contentID = nil
		@parentFolderName = ""
	end
end
