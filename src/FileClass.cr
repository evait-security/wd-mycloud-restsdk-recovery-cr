require "./Node"
class FileClass

	property id
	property name
	property mimeType
	property contentID
	property parentID

	def initialize(@id : String, @name : String, @parentID : String, @mimeType : String, @contentID : String)
	end

	def initialize(@id : String, @name : String, @mimeType : String)
		@parentID = nil
		@contentID = nil
	end

	def initialize(@name : String)
		@id = nil
		@mimeType = "application/x.wd.dir"
		@contentID = nil
		@parentID = nil
	end

end
