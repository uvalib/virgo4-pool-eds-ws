Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }


run Cuba
