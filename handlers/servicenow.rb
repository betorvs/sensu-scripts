#!/usr/bin/env ruby

#
# versao 1.0
# Roberto Scudeller: beto.rvs at gmail dot com
#

require 'sensu-handler'
require 'json'
require 'openssl'

class Servicenow < Sensu::Handler
  option :json_config,
    description: 'Configuration name',
    short: '-j JSONCONFIG',
    long: '--json JSONCONFIG',
    default: 'servicenow'

  def service_now_url
    get_setting('service_now_url')
  end 

  def proxy_addr
    get_setting('proxy_addr')
  end

  def proxy_port
    get_setting('proxy_port')
  end

  def message_prefix
    get_setting('message_prefix')
  end

  def app_username
    get_setting('app_username')
  end

  def app_password
    get_setting('app_password')
  end

  def incident_key
    if @event['check']['subscribers']
      @event['client']['name'] + '/' + @event['check']['subscribers'] + '/' + @event['check']['name']
    else
      @event['client']['name'] + '/' + @event['check']['name']
    end
  end

  def event_id
    @event['id'] 
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def handle
    case @event['action']
      when 'create'
        post_data("Problem Check: #{incident_key}")
        inc_number = query_data(event_id,'number')
        puts "Problem #{incident_key} [ #{inc_number} ]"
      when 'resolve'
        inc = query_data(event_id,'sys_id')
        inc_number = query_data(event_id,'number')
        #puts "Debug: #{event_id} #{inc_number} #{inc} "
        close_data(inc)
        puts "Resolved #{incident_key} [ #{inc_number} ]"
    end

  end

  def post_data(notice)
    uri = URI(service_now_url)

    if (defined?(proxy_addr)).nil?
      http = Net::HTTP.new(uri.host, uri.port)
    else
      http = Net::HTTP::Proxy(proxy_addr, proxy_port).new(uri.host, uri.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

    req = Net::HTTP::Post.new(uri, 'Content-Type' =>'application/json')

    text = notice
    req.body = payload(text).to_json
    req.basic_auth app_username, app_password
    response = http.request(req)
    verify_response(response)
  end

  def query_data(notice,question)
    uri_query = "?sysparm_query=active=true&sys_updated_by=#{app_username}&state=3&sysparm_limit=10&sysparm_fields=sys_id,number,user_input,short_description"

    uri = URI("#{service_now_url}#{uri_query}")

    if (defined?(proxy_addr)).nil?
      http = Net::HTTP.new(uri.host, uri.port)
    else
      http = Net::HTTP::Proxy(proxy_addr, proxy_port).new(uri.host, uri.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

    req = Net::HTTP::Get.new(uri)
    req.basic_auth app_username, app_password
    response = http.request(req)
    verify_response(response)
    incident = JSON.parse(response.body)
    id_incident = incident["result"].find {|q1| q1['user_input']=="#{notice}"}["#{question}"]
    id_incident
    
  end

  def close_data(notice)
    uri_query = "#{notice}"
    uri = URI("#{service_now_url}/#{uri_query}")

    if (defined?(proxy_addr)).nil?
      http = Net::HTTP.new(uri.host, uri.port)
    else
      http = Net::HTTP::Proxy(proxy_addr, proxy_port).new(uri.host, uri.port)
    end

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

    req = Net::HTTP::Put.new(uri.request_uri)
    text = '{ "state": 7, "comments": "SENSU Closed Without Human Action" }'
    req.body = text
    req.initialize_http_header ({ 'Content-Type'=>'application/json','Accept'=>'application/json' })
    req.basic_auth app_username, app_password
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
    "short_description" => [message_prefix, notice].compact.join(' '),
    "contact_type" => 'alert',
    "priority" => 3,
    "user_input" => event_id
    }
  end

end
