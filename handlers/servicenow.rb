#!/usr/bin/env ruby

#
# versao 1.0
# roberto.scudeller at walmart.com
#
# 1.1: Closes into loop, max 10 INCs
# 1.0: Open and close INC into ServiceNow (SN)

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

  def severity
    unless @event['client']['severity'].nil?
	    severity = @event['client']['severity'].gsub(/[^0-9]/, '').to_i
    else
	    severity = 4
    end
    severity
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def handle
    case @event['action']
      when 'create'
        post_data("Problem Check: #{incident_key}")
        inc = query_data(event_id,'number')
	inc.each do |k,v|
	  inc_number = k['number']
          puts "Problem #{incident_key} [ #{inc_number} Severity: #{severity} ]"
	end
      when 'resolve'
        inc = query_data(event_id,'sys_id')
        #puts "Debug: #{inc} "
        if inc != "not_found"
	  inc.each do |k,v|
            inc_number = k['number']
	    inc_id = k['sys_id']
            #puts "Debug: #{event_id} #{inc_number} #{inc_id} "
            close_data(inc_id)
            puts "Resolved #{incident_key} [ #{inc_number} Severity: #{severity} ]"
	  end
        else
          puts "Resolved #{incident_key} [ INC Not Found #{severity} ]"
        end
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
    # remove verify because if INC is closed, SN will return 400 bad request
    #verify_response(response)
    incident = JSON.parse(response.body)
    # If this user dont have INCs
    if incident["result"].empty?
      id_incident = "not_found"
      id_incident
    else
      # If this user hava a INC but event_id is different
      id_incident = incident["result"].select {|q1| q1['user_input']=="#{notice}"}
      if id_incident.empty?
	id_incident = "not_found"
	id_incident
      else
	id_incident
      end
    end
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
    text = '{ "state": 7, "close_code": "resolved without activity", "close_notes": "SENSU Closed Without Human Action", "comments": "SENSU Closed Without Human Action" }'
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

  def build_description
    [
      @event['client']['address'],
      @event['client']['docs'],
      @event['client']['logs'],
      @event['client']['graphs'],
      @event['check']['output'].strip
    ].join(' ')
  end

  def payload(notice)
    {
    "short_description" => [message_prefix, notice].compact.join(' '),
    "contact_type" => 'alert',
    "priority" => severity,
    "assignment_group" => '64b3abc66f64a1009290aa6fae3ee4a2',
    "description" => build_description,
    "user_input" => event_id
    }
  end

end
