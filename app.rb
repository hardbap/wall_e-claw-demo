#require File.expand_path('../../lib/faye/websocket', __FILE__)
require 'faye/websocket'
require 'rack'
require 'bundler/setup'
require 'wall_e'

static = Rack::File.new(File.dirname(__FILE__))
wall_e = WallE::Assembler.create
claw = wall_e.Claw(10, 9)
claw.center

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, ['irc', 'xmpp'], :ping => 5)
    p [:open, ws.url, ws.version, ws.protocol]

    ws.onmessage = lambda do |event|
      servo, degrees = event.data.split(":")
      msg = "Moved the #{servo} #{degrees} degrees"
      what = servo == 'claw' ? :pinch : :tilt
      claw.send(what, degrees.to_i)
      ws.send(msg)
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

