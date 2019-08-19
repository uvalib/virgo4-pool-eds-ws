require 'rubygems'
require 'bundler'
require 'logger'
Bundler.setup

$logger = Logger.new($stdout)

if ENV['RACK_ENV'] != 'production'
  require 'dotenv/load'
  require 'pry-debugger-jruby'

  $logger.level = Logger::DEBUG
else
  # This is already included in dev
  use Rack::CommonLogger, $logger
end

require 'rack/post-body-to-params'
use Rack::PostBodyToParams

Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

run Cuba

# Override logger to use ms
class Rack::CommonLogger
private
  def log(env, status, header, began_at)
    length = extract_content_length(header)

    msg = FORMAT % [
      env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
      env["REMOTE_USER"] || "-",
      Time.now.strftime("%d/%b/%Y:%H:%M:%S %z"),
      env['REQUEST_METHOD'],
      env['PATH_INFO'],
      env['QUERY_STRING'].empty? ? "" : "?#{env['QUERY_STRING']}",
      env['HTTP_VERSION'],
      status.to_s[0..3],
      length,
      (Time.now - began_at) * 1000 ]

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
