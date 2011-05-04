require 'base64'

module Palmade::CandyWrapper
  module MiksPanel
    HTTP = Palmade::CandyWrapper.http

    MIXPANEL_API_SITE = 'api.mixpanel.com'

    class MiksPanelFail < HttpFail; end

    extend Mixins::CommonFacilities
    self.secure = true

    def self.api_url(path)
      "#{http_proto}://#{MIXPANEL_API_SITE}/#{path}"
    end

    # Useful properties to pass, distinct_id and ip address.
    #
    def self.track(token, event, properties = { }, options = { })
      properties = stringify_keys(properties || { })

      properties['token'] = token
      unless properties.include?('time')
        properties['time'] = Time.now.utc.to_i
      end

      params = {
        'event' => event,
        'properties' => properties
      }

      encoded = Base64.encode64(Yajl::Encoder.encode(params)).gsub(/\n/, '')
      query = {
        'data' => encoded
      }

      query['test'] = 1 if options[:test]

      logger.debug { "  Mix event %s %s %s" % [ event, properties.inspect, query.inspect ] }

      url = '%s?%s' % [ api_url('track/'),
                        query_string(query) ]

      logger.debug { "  HTTP get #{url}" }

      resp = HTTP.get(url)
      unless resp.fail?
        resp.read.strip == '1' ? true : false
      else
        resp.raise_http_error
      end
    end
  end
end
