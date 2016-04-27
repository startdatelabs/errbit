require 'uri'
require 'open-uri'

module AirbrakeApi
  class SourceMapConsumer
    class << self
      def process(backtrace_line)
        minified_url = backtrace_line['file']

        minified_url_path = file_name(minified_url)

        js_mapping = JsMapping.find_or_create(minified_url_path)

        unless js_mapping.source_map_url_path
          js_mapping.source_map_url_path = get_source_map_url(minified_url)
          js_mapping.save!

          download_map_file(asset_url(minified_url, js_mapping.source_map_url_path)) unless js_mapping.source_map_url_path == 'none'
        end

        if js_mapping.source_map_url_path == 'none'
          backtrace_line
        else
          map_file_path = file_path(file_name(js_mapping.source_map_url_path), maps_folder)
          map_line = backtrace_line['line']
          map_column = backtrace_line['column']

          result = POSIX::Spawn::Child.new("node node/map_consumer.js '#{ map_file_path }' #{ map_line } #{ map_column }")
          parsed = JSON.parse(result.out)
          {
            method: parsed['name'],
            file:   asset_url(minified_url, parsed['source']),
            number: parsed['line'],
            column: parsed['column']
          }
        end
      end


      private

      def asset_url(minified_url, path)
        url = URI.parse(minified_url)
        url.path = path
        url.to_s
      end

      def get_source_map_url(minified_url)
        minified_path = download_minified_file(minified_url)
        content = File.read(minified_path)
        mapping = content.match("//# sourceMappingURL=(.*)[\\s]*$")
        mapping&.size == 2 ? mapping[1] : 'none'
      end

      def download_minified_file(url)
        download_file(url, minified_folder)
      end

      def download_map_file(url)
        download_file(url, maps_folder)
      end

      def download_file(url, folder)
        file_name = file_name(url)
        file_path = file_path(file_name, folder)

        File.open(file_path, "wb") do |saved_file|
          open(url, "rb") do |read_file|
            saved_file.write(read_file.read)
          end
        end

        file_path
      end

      def file_name(url)
        uri = URI.parse(url)
        File.basename(uri.path)
      end

      def file_path(file_name, folder)
        File.join(folder, file_name)
      end

      def minified_folder
        @minified_folder ||= begin
          folder = File.join(Rails.root, 'tmp', 'minified_js')
          FileUtils.mkdir_p folder
          folder
        end
      end

      def maps_folder
        @maps_folder ||= begin
          folder = File.join(Rails.root, 'tmp', 'maps_js')
          FileUtils.mkdir_p folder
          folder
        end
      end
    end
  end
end
