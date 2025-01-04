# Festivus-inspired single-file micro JSON API

require "json"
require "toro"

class WebApp < Toro::Router
  def routes

  end
end

begin
  WebApp.run do |server|
    puts "Listening on http://0.0.0.0:3000"
    server.listen "::", 3000
  end
ensure
end

Fiber.yield
