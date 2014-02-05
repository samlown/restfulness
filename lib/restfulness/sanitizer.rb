module Restfulness
  module Sanitizer
    SANITIZED = 'FILTERED'.freeze

    def self.sanitize_hash(arg)
      @hash_sanitizer ||= Hash.new(Restfulness.sensitive_params)
      @hash_sanitizer.sanitize(arg)
    end

    def self.sanitize_query_string(arg)
      @query_string_sanitizer ||= QueryString.new(Restfulness.sensitive_params)
      @query_string_sanitizer.sanitize(arg)
    end

    class AbstractSanitizer
      attr_reader :sensitive_params, :sensitive_param_matcher

      def initialize(*sensitive_params)
        @sensitive_params = [*sensitive_params].flatten.map(&:downcase)
        @sensitive_param_matcher = Regexp.new("\\A#{@sensitive_params.join('|')}", Regexp::IGNORECASE)
      end

      def sensitive_param?(param)
        sensitive_param_matcher === param.to_s
      end

      def sanitize(arg)
        raise 'not implemented'
      end
    end

    # Clean a hash of sensitive data. Works on nested hashes
    class Hash < AbstractSanitizer
      def sanitize(h)
        return h if sensitive_params.empty? || h.empty?
        duplicate = h.dup
        duplicate.each_pair do |k, v|
          duplicate[k] = if sensitive_param?(k)
            SANITIZED
          elsif v.is_a?(::Hash)
            sanitize(v)
          else
            v
          end
        end
        duplicate
      end
    end

    # Clean a query string of sensitive data
    class QueryString < AbstractSanitizer
      PARSER = /
        ([^&;=]+?) # param key
        (\[.*?\])? # optionally a nested param, ie key[9]
        =          # divider
        ([^&;=]+)  # param value
      /x
      def sanitize(qs)
        return qs if sensitive_params.empty? || qs.length == 0
        qs.gsub(PARSER) do |query_param|
          if sensitive_param?($1)
            "#{$1}#{$2}=#{SANITIZED}"
          else
            query_param
          end
        end
      end
    end
  end
end