module Agents
  class IpinfoAbuseContactDataAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '1h'

    description do
      <<-MD
      The Github notification agent fetches notifications and creates an event by notification.

      `debug` is used for verbose mode.

      `ip` for the ip wanted.

      `logs` is not mandatory, just available if an email agent is after this one for completing for example an abuse report.

       If `emit_events` is set to `true`, the server response will be emitted as an Event. No data processing
       will be attempted by this Agent, so the Event's "body" value will always be raw text.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "address": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
            "country": "XX",
            "email": "XXXXXXXXXXXXXXXXXXXXXX",
            "name": "XXXXXXXXXXXXXXXXXXXX",
            "network": "XXXXXXXXXXXXXX",
            "phone": "XXXXXXXXXX",
            "ip": "XXXXXXXXXX"
          }
    MD

    def default_options
      {
        'ip' => '',
        'host' => '',
        'type' => '',
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'logs' => '',
        'emit_events' => 'true'
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :ip, type: :string
    form_configurable :host, type: :string
    form_configurable :type, type: :string
    form_configurable :logs, type: :string
    form_configurable :emit_events, type: :boolean

    def validate_options

      unless options['ip'].present?
        errors.add(:base, "ip is a required field")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          fetch
        end
      end
    end

    def check
      fetch
    end

    private

    def fetch

      uri = URI.parse("https://ipinfo.io/products/ip-abuse-contact-api")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/x-www-form-urlencoded; charset=UTF-8"
      request["Authority"] = "ipinfo.io"
      request["Accept"] = "*/*"
      request["X-Requested-With"] = "XMLHttpRequest"
      request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.115 Safari/537.36"
      request["Sec-Gpc"] = "1"
      request["Origin"] = "https://ipinfo.io"
      request["Sec-Fetch-Site"] = "same-origin"
      request["Sec-Fetch-Mode"] = "cors"
      request["Sec-Fetch-Dest"] = "empty"
      request["Referer"] = "https://ipinfo.io/products/ip-abuse-contact-api"
      request["Accept-Language"] = "fr,en-US;q=0.9,en;q=0.8"
      request.set_form_data(
        "input" => "#{interpolated['ip']}",
      )
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)
  
      if interpolated['debug'] == 'true'
        log "response body : #{payload}"
      end

      payload[:logs] = "#{interpolated['logs']}"
      payload[:ip] = "#{interpolated['ip']}"
      payload[:host] = "#{interpolated['host']}"
      payload[:type] = "#{interpolated['type']}"
  
      if interpolated['emit_events'] == 'true'
        create_event :payload => payload
      end
    end
  end
end
