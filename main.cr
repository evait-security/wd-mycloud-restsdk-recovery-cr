require "option_parser"
require "sqlite3"
require "db"
require "kernel"
require "file"
require "io"

ERROR="[-] ERROR: "

database_index=""
backup_db=""
files_dir=""
output_dir=""
action=""

OptionParser.parse do |parser|
	parser.banner = "WD MyCloud rest-sdk recovery"
	
	parser.on("-d DATABASE", "--database=DATABASE", "Path to the index.db file") {|_DATABASE| database_index = _DATABASE }
	parser.on("-b BACKUP", "--backup=BACKUP", "Path to the recovered.db file") {|_BACKUP| backup_db = _BACKUP }
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

case action
when "restore" 
	restore(database_index, output_dir)
	exit 0
else 
	puts "Trying to restore the contents"
end 


error=false
if database_index.empty?
	STDERR.puts "#{ERROR} Path to database missing (try -h for help)"
	error = true
end

if backup_db.empty?
	STDERR.puts "#{ERROR} Path to backup database missing (try -h for help)"
	error = true
end

if files_dir.empty?
	STDERR.puts "#{ERROR} Path to files direcotry missing (try -h for help)"
	error = true
end

exit 1 if error

begin 
	DB.open "sqlite3://#{database_index}" do |db|
			db.query "SELECT id FROM files;"
	end
rescue e 
	if e.message.as(String).includes?("malformed")
		STDERR.puts "#{ERROR} The Database seems malformed, you can try to restore it with this program. Check out -h,--help for more information"
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

