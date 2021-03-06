#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ check amqp alive plugin
# ===
#
# DESCRIPTION:
# This plugin checks if RabbitMQ server is alive using AMQP
#
# PLATFORMS:
#   Linux, BSD, Solaris
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: bunny
#
# LICENSE:
# Copyright 2013 Milos Gajdos
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'bunny'

# main plugin class
class CheckRabbitAMQPAlive < Sensu::Plugin::Check::CLI
  option :host,
         description: 'RabbitMQ host',
         short: '-w',
         long: '--host HOST',
         default: 'localhost'

  option :vhost,
         description: 'RabbitMQ vhost',
         short: '-v',
         long: '--vhost VHOST',
         default: '%2F'

  option :username,
         description: 'RabbitMQ username',
         short: '-u',
         long: '--username USERNAME',
         default: 'guest'

  option :password,
         description: 'RabbitMQ password',
         short: '-p',
         long: '--password PASSWORD',
         default: 'guest'

  option :port,
         description: 'RabbitMQ AMQP port',
         short: '-P',
         long: '--port PORT',
         default: '5672'

  option :ssl,
         description: 'Enable SSL for connection to RabbitMQ',
         long: '--ssl',
         boolean: true,
         default: false

  option :tls_cert,
         description: 'TLS Certificate to use when connecting',
         long: '--tls-cert CERT',
         default: nil

  option :tls_key,
         description: 'TLS Private Key to use when connecting',
         long: '--tls-key KEY',
         default: nil

  option :no_verify_peer,
         description: 'Disable peer verification',
         long: '--no-verify-peer',
         boolean: true,
         default: true

  def run
    res = vhost_alive?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def vhost_alive?
    host           = config[:host]
    port           = config[:port]
    username       = config[:username]
    password       = config[:password]
    vhost          = config[:vhost]
    ssl            = config[:ssl]
    tls_cert       = config[:tls_cert]
    tls_key        = config[:tls_key]
    no_verify_peer = config[:no_verify_peer]

    begin
      conn = Bunny.new("amqp#{ssl ? 's' : ''}://#{username}:#{password}@#{host}:#{port}/#{vhost}",
                       tls_cert:    tls_cert,
                       tls_key:     tls_key,
                       verify_peer: no_verify_peer)
      conn.start
      conn.close if conn.connected?
      { 'status' => 'ok', 'message' => 'RabbitMQ server is alive' }
    rescue Bunny::PossibleAuthenticationFailureError
      { 'status' => 'critical', 'message' => 'Possible authentication failure' }
    rescue Bunny::TCPConnectionFailed
      { 'status' => 'critical', 'message' => 'TCP connection refused' }
    rescue => e
      { 'status' => 'unknown', 'message' => e.message }
    end
  end
end
