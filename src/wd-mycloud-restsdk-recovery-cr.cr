require "option_parser"
require "colorize"
require "sqlite3"
require "db"
require "kernel"
require "file"
require "dir"
require "io"
require "./Node"
require "./recoverer"

module Wd_mycloud_restsdk_recovery_cr

	VERSION = "0.1.0"

	database_index = ""
	backup_db = ""
	files_dir = ""
	output_dir = ""

	quite = false
	action = ""
  objParser = ""

	##### Statistics #####
	files_found = 0
	root_folders = 0 
	folders = 0


	OptionParser.parse do |parser|
		parser.banner = "WD MyCloud rest-sdk recovery"

		parser.on("-d DATABASE", "--database=DATABASE", "Path to the index.db file") {|_DATABASE| database_index = _DATABASE }
		# parser.on("-bd BACKUP_DATABASE", "--backup-database=BACKUP_DATABASE", "Path to the backup index.db file") {|_DATABASE| database_backup = _DATABASE }
		parser.on("-f FILES_DIR", "--files=FILES_DIR", "Path to the directory containing the unorganized files") {|_FILES_DIR| files_dir = _FILES_DIR }
		parser.on("-o OUT_DIR", "--output=OUT_DIR", "(optional) Path to the directory where the directory structure should be created ") {|_OUT_DIR| output_dir = _OUT_DIR }
		parser.on("-r", "--restore", "Tries to restore the given database, uses -o for output(dir|name)") {action = "restore"}
		parser.on("-q", "--quite", "Disables output to the terminal") {quite = true}

		parser.on "-h", "--help", "Show help" do 
			puts parser 
			exit(0)
		end

		parser.invalid_option do |flag|
      puts "[-] #{flag} is not a valid option".colorize.red
			exit(1)
		end
    
    objParser = parser # ToDo: bad coding style
	end

  if database_index.empty?
    puts "[-] no database was defined".colorize.red
    puts objParser
    exit(1)
  elsif files_dir.empty?
    puts "[-] no source file directory was defined".colorize.red
    puts objParser
    exit(1)
  elsif output_dir.empty?
    puts "[!] no output directory was defined. Using defaults: __out".colorize.yellow
    output_dir = "__out"
  end

	if action == "restore"
		begin
			Recoverer.restore(database_index, output_dir, quite)
		rescue e
      puts "[-] #{e}".colorize.red
      exit(1)
		end
		exit 0
	end

	Recoverer.recoverDB(database_index, files_dir, output_dir, quite)
end
