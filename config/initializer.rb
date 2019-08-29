# App Initialization used in config.ru and test.rb

# Prometheus
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'
Cuba.use Rack::Deflater, if: ->(_, _, _, body) { body.respond_to?( :map ) && body.map(&:bytesize).reduce(0, :+) > 512 }
Cuba.use Prometheus::Middleware::Collector
Cuba.use Prometheus::Middleware::Exporter

# Logger
$logger = Logger.new($stdout)
Cuba.use Rack::CommonLogger, $logger unless ENV['RACK_ENV'] == 'development'

# automatic CORS support
Cuba.use Rack::Cors do
  allow do
    origins '*'
    resource '/api/search', headers: :any, methods: [:get, :post, :options]
  end
end

# Converts POST body to params
Cuba.use Rack::PostBodyToParams

# I18n
I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
I18n.default_locale = :en
module I18nHelper
  def t key
    # normalize keys
    I18n.t(key.downcase.gsub(' ', '_'), options = {})
  end
end
Cuba.plugin I18nHelper

# Override logger to use ms
class Rack::CommonLogger
  private
  def log(env, status, header, began_at)
    length = extract_content_length(header)

    msg = %{%s - %s [%s] "%s %s%s %s" %d %s %0.0f\n} % [
      env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
      env["REMOTE_USER"] || "-",
      Time.now.strftime("%d/%b/%Y:%H:%M:%S %z"),
      env['REQUEST_METHOD'],
      env['PATH_INFO'],
      env['QUERY_STRING'].empty? ? "" : "?#{env['QUERY_STRING']}",
      env['HTTP_VERSION'],
      status.to_s[0..3],
      length,
      ((Time.now - began_at) * 1000 ).round]

    logger = @logger || env['RACK_ERRORS']
    # Standard library logger doesn't support write but it supports << which actually
    # calls to write on the log device without formatting
    if logger.respond_to?(:write)
      logger.write(msg)
    else
      logger << msg
    end
  end
end

