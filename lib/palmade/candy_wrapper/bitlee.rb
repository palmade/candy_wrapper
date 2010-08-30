# -*- encoding: utf-8 -*-

module Palmade::CandyWrapper
  module Bitlee
    HTTP = Palmade::CandyWrapper.http

    BITLEE_API_SITE = 'api.bit.ly'
    BITLEE_API_VERSION = 'v3'

    class BitleeFail < HttpFail; end

    extend Mixins::CommonFacilities
    self.secure = false

    def self.api_url(path)
      "#{http_proto}://#{BITLEE_API_SITE}/#{BITLEE_API_VERSION}/#{path}"
    end

    def self.shorten(login, api_key, long_url)
      http_opts = prepare_http_opts
      params = prepare_params(login, api_key)

      params['longUrl'] = long_url
      shorten_url = api_url('shorten')

      logger.debug { "#{shorten_url} => #{http_opts.inspect}" }

      resp = HTTP.post(shorten_url, params, nil, http_opts)
      unless resp.fail?
        parse_json_response(resp)
      else
        resp.raise_http_error
      end
    end

# "{ \"status_code\": 200, \"status_txt\": \"OK\", \"data\": { \"long_url\": \"http:\\/\\/app.tweetitow.com\", \"url\": \"http:\\/\\/twtw.co\\/9hH1bl\", \"hash\": \"9hH1bl\", \"global_hash\": \"9dF0px\", \"new_hash\": 0 } }\n"
    def self.parse_json_response(resp)
      json_resp = resp.json_read

      case json_resp['status_code']
      when 200
        json_resp = json_resp['data']
      else
        raise BitleeFail.new("Bit.ly API response error #{json_resp['status_code']} #{json_resp['status_txt']}", resp)
      end

      json_resp
    end

    def self.prepare_http_opts(options = { })
      http_opts = {
        :headers => { },
        :charset_encoding => 'utf-8'
      }

      add_user_agent(http_opts)

      http_opts
    end

    def self.add_user_agent(http_opts)
      unless user_agent.nil?
        http_opts[:headers]["User-Agent"] = user_agent
      end
    end

    def self.prepare_params(login, api_key)
      params = { }
      params['login'] = login
      params['apiKey'] = api_key
      params['format'] = 'json'

      params
    end
  end
end
