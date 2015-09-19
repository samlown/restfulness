module Restfulness
  module Headers

    # The Accept header handler provides an array of Media Types that the
    # client is willing to accept.
    #
    # Based on a simplified RFC2616 implementation, each media type is stored
    # and ordered.
    #
    # Restfulness does not currently deal with the special 'q' paremeter defined
    # in the standard as quality is not something APIs normally need to handle.
    #
    # Aside from media type detection, a useful feature of the accept header is to 
    # provide the desired version of content to provide in the response. This class
    # offers a helper method that will attempt to determine the version.
    #
    # Given the HTTP header:
    #
    #   Accept: application/com.example.api+json;version=1
    #
    # The resource instace has access to the version via:
    #
    #   request.accept.version == "1"
    #
    class Accept

      # The -ordered- array of media types provided in the headers
      attr_accessor :media_types

      def initialize(str = "")
        self.media_types = []
        parse(str) unless str.empty?
      end

      def parse(str)
        types = str.split(',').map{|t| t.strip}
 
        # Attempt to crudely determine order based on length, and store
        types.sort{|a,b| b.length <=> a.length}.each do |t|
          media_types << MediaType.new(t)
        end
      end

      # Request the version, always assumes that the first media type is the most relevant
      def version
        media_types.first.version
      end

      def json?
        media_types.each do |mt|
          return true if mt.json?
        end 
        false
      end

      def xml?
        media_types.each do |mt|
          return true if mt.xml?
        end 
        false
      end

    end

  end
end
