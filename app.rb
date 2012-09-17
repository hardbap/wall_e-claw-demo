#require File.expand_path('../../lib/faye/websocket', __FILE__)
require 'faye/websocket'
require 'rack'
require 'bundler/setup'
require 'wall_e'

static = Rack::File.new(File.dirname(__FILE__))
wall_e = WallE::Assembler.create
servo = wall_e.Servo(9, range: 60..144)
servo.min

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, ['irc', 'xmpp'], :ping => 5)
    p [:open, ws.url, ws.version, ws.protocol]

    ws.onmessage = lambda do |event|
      begin
        servo.move_to(event.data.to_i)
        ws.send(event.data)
      rescue WallE::Servo::OutOfBoundsError
        ws.send("Servo doesn't support moving to #{event.data}")
      end
    end

    ws.onclose = lambda do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    ws.rack_response

  else
    static.call(env)
  end
end

