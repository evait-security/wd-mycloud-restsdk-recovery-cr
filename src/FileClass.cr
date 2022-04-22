require "./Node"
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
