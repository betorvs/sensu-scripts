#!/usr/bin/env ruby

#
# versao 1.0
# roberto.scudeller at oi.net.br
#

require 'sensu-handler'
require 'json'
require 'openssl'

class Postjson < Sensu::Handler
  option :json_config,
    description: 'Configuration name',
    short: '-j JSONCONFIG',
    long: '--json JSONCONFIG',
    default: 'postjson'

  def postjson_webhook_url
    get_setting('webhook_url')
  end 

  def postjson_channel
    get_setting('channel')
  end

  def postjson_proxy_addr
    get_setting('proxxy_addr')
  end

  def postjson_proxy_port
    get_setting('proxy_port')
  end

  def postjson_message_prefix
    get_setting('message_prefix')
  end

  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def incident_link
    'https://monitoring.uchiwa.home/#/client/production/' + @event['client']['name'] + '?check=' + @event['check']['name']
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def handle
    playbook = "Playbook:  #{@event['check']['playbook']}" if @event['check']['playbook']
    description = @event['check']['notification'] || build_description
    case @event['action']
      when 'create'
        post_data("Check: #{incident_key} <br> Description: #{description} <br>Link: #{incident_link} <br> #{playbook}")
      when 'resolve'
        puts "Resolvido #{incident_key} Description: #{description} "
    end

  end

  def build_description
    [
      @event['check']['output'].strip,
      @event['client']['address'],
      @event['client']['subscriptions'].join(' ')
    ].join(' ')
  end

  def post_data(notice)
    uri = URI(postjson_webhook_url)

    if (defined?(postjson_proxy_addr)).nil?
      http = Net::HTTP.new(uri.host, uri.port)
    else
      http = Net::HTTP::Proxy(postjson_proxy_addr, postjson_proxy_port).new(uri.host, uri.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

    req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}", initheader = {'Content-Type' =>'application/json'})

    text = notice
    req.body = payload(text).to_json
    puts req.body
    response = http.request(req)
    verify_response(response)
  end

  def verify_response(response)
    case response
    when Net::HTTPSuccess
      true
    else
      fail response.error!
    end
  end

  def payload(notice)
    {
      "incident"=> {
        "description"=> [postjson_message_prefix, notice].compact.join(' '),
        "summary"=> incident_key
      }
    }
  end

    def check_status
    @event['check']['status']
  end
end
