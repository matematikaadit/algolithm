require 'webrick'

port = ARGV.first || 80

server = WEBrick::HTTPServer.new(:DocumentRoot => Dir.pwd, :Port => port.to_i)

# trap signals to invoke the shutdown procedure cleanly
%w{ INT TERM }.each do |signal|
  trap(signal){ server.shutdown}
end

server.start

