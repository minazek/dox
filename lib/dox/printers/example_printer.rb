require 'rexml/document'

module Dox
  module Printers
    class ExamplePrinter < BasePrinter
      def print(example)
        self.example = example
        @json_hash['summary'] = example.desc.capitalize
        add_example_request
        add_example_response
      end

      private

      attr_accessor :example

      def add_example_request
        request_body = existing_hash(@json_hash, 'requestBody')
        request_body['content'] = add_request_content_and_hash
      end

      def add_request_content_and_hash
        content_hash = {}
        header_hash = {}

        content_hash[add_request_headers(example.request_headers)] = header_hash

        unless example.request_body.empty?
          add_example_and_schema(example.request_body, header_hash, Dox.config.schema_request_folder_path)
        end

        content_hash
      end

      def add_example_response
        responses = existing_hash(@json_hash, 'responses')
        status = existing_hash(responses, example.response_status.to_s)
        add_statuses(status)
      end

      def add_statuses(status_hash)
        status_hash['description'] = Util::Http::HTTP_STATUS_CODES[example.response_status]
        status_hash['content'] = add_response_content_and_hash
      end

      def add_response_content_and_hash
        content_hash = {}
        header_hash = {}

        content_hash[add_response_headers(example.response_headers)] = header_hash

        unless example.response_body.empty?
          add_example_and_schema(example.response_body, header_hash, Dox.config.schema_response_folder_path)
        end

        content_hash
      end

      def add_example_and_schema(body, header_hash, path)
        header_hash['example'] = JSON.parse(body)
        return if example.schema.nil?

        header_hash['schema'] = { '$ref' => File.join(path, "#{example.schema}.json") }
      end

      def add_request_headers(headers)
        headers.map do |key, value|
          return value if key == 'Accept'
        end
      end

      def add_response_headers(headers)
        headers.map do |key, value|
          return value if key == 'Content-Type'
        end
      end
    end
  end
end
