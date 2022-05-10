# Western Digital (WD) MyCloud RestSDK Recovery Tool
## Background
WD MyCloud devices do not use the ext4 file system directly like other external drives, but they store files with random generated names and directory structures. If your MyCloud is not working correctly, reading the SQLite database on the device is neccessary in order determine the original file structure and names.

## Why another tool?
There are already exist commercial and open source solutions like "https://github.com/springfielddatarecovery/mycloud-restsdk-recovery-script" but not really performant and with some bugs. We want to create an open source performant tool with some extra functionality like restoring SQLite databases in case of corruption or restoring files which cannot be found in the database.

## Usage
The tool is written in crystal lang and will be available using pre compiled binaries and of cource compiling it directly from source.

### Building 

shards install
shards build

	After that the binary will be in the bin/ directory.

	WD MyCloud rest-sdk recovery
		-d DATABASE, --database=DATABASE Path to the index.db file
		-f FILES_DIR, --files=FILES_DIR  Path to the directory containing the unorganized files
		-o OUT_DIR, --output=OUT_DIR     (optional) Path to the directory where the directory structure should be created
		-r, --restore                    Tries to restore the given database, uses -o for output(dir|name)
		-q, --quite                      Disables output to the terminal
		-h, --help                       Show help
