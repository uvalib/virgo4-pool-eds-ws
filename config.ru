require 'rubygems'
require 'bundler'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

Bundler.require :default, ENV['RACK_ENV']

use Rack::Deflater, if: ->(_, _, _, body) { body.respond_to?( :map ) && body.map(&:bytesize).reduce(0, :+) > 512 }
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

$logger = Logger.new($stdout)
use Rack::CommonLogger, $logger

use Rack::Cors do
  allow do
    origins '*'
    resource '/api/search/*', headers: :any, methods: :post
  end
end

use Rack::PostBodyToParams

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

run Cuba

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
