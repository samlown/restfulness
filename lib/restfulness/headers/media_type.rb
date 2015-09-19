module Restfulness
  module Headers

    # Generic media type handling according to the RFC2616 HTTP/1.1 header fields
    # specification.
    #
    # If instantiated with a string, the MediaType object will attempt to parse and
    # set the objects attributes.
    #
    # If an empty or no string is provided, the media-type can be prepared by setting
    # the type, subtype and optional parameters values. Calling the #to_s method will
    # provide the compiled version.
    #
    # Accessor names and parsing is based on details from https://en.wikipedia.org/wiki/Media_type.
    #
    class MediaType

      # First part of the mime-type, typically "application", "text", or similar.
      # Vendor types are not supported.
      attr_accessor :type

      # Always last part of definition. For example:
      #
      #  * "json" from "application/json"
      #  * "user" from "application/vnd.example.user+json;version=1"
      #
      attr_accessor :subtype

      # Refers to the vendor part of type string, for example:
      #
      #  * "example" from "application/vnd.example.user+json"
      #
      attr_accessor :vendor

      # When using vendor content types, a suffix may be provided:
      #
      #  * "json" from "application/vnd.example.user+json"
      #
      attr_accessor :suffix

      # Hash of parameters using symbols as keys
      attr_accessor :parameters

      def initialize(str = "")
        # Defaults
        self.type = "*"
        self.subtype = "*"
        self.vendor = ""
        self.suffix = ""
        self.parameters = {}

        # Attempt to parse string if provided
        parse(str) unless str.empty?
      end

      def parse(str)
        # Split between base and parameters
        parts = str.split(';').map{|p| p.strip}
        t = parts.shift.split('/', 2)
        self.type = t[0] if t[0]

        # Handle subtype, and more complex vendor + suffix
        if t[1]
          (v, s) = t[1].split('+',2)
          self.suffix = s if s
          s = v.split('.')
          s.shift if s[0] == 'vnd'
          self.subtype = s.pop
          self.vendor = s.join('.') unless s.empty?
        end

        # Finally, with remaining parts, handle parameters
        self.parameters = Hash[parts.map{|p| (k,v) = p.split('=', 2); [k.to_sym, v]}]
      end

      def to_s
        base = "#{type}/"
        if !vendor.empty?
          base << ["vnd", vendor, subtype].join('.')
        else
          base << subtype 
        end
        base << "+#{suffix}" unless suffix.empty?
        base << ";" + parameters.map{|k,v| "#{k}=#{v}"}.join(';') unless parameters.empty?
        base
      end

      def ==(value)
        if value.is_a?(String)
          value = self.class.new(value)
        end
        raise "Invalid type comparison!" unless value.is_a?(MediaType)
        type == value.type &&
          subtype == value.subtype &&
          vendor == value.vendor &&
          suffix == value.suffix &&
          parameters == value.parameters
      end

      def charset
        parameters[:charset]
      end

      def version
        parameters[:version]
      end

      def json?
        type == "application" && (subtype == "json" || suffix == "json")
      end

      def xml?
        type == "application" && (subtype == "xml" || suffix == "xml")
      end

      def text?
        type == "text" && subtype == "plain"
      end

      def form?
        type == "application" && subtype == "x-www-form-urlencoded"
      end

    end

  end
end
