module Palmade::CandyWrapper
  module Posporo
    HTTP = Palmade::HttpService::Http

    class PosporoFail < StandardError
      attr_reader :response

      def initialize(msg = nil, response = nil)
        super(msg)
        @response = response
      end
    end

    def self.user_agent=(ua); @@ua = ua; end
    def self.user_agent
      if defined?(@@ua)
        @@ua
      else
        nil
      end
    end

    def self.logger=(l); @@logger = l; end
    def self.logger
      if defined?(@@logger)
        @@logger
      else
        @@logger = Palmade::CandyWrapper.logger
      end
    end

    def self.secure=(s)
      @@secure = s
    end

    def self.secure?
      @@secure ||= true
    end

    def self.http_proto
      secure? ? "https" : "http"
    end

    def self.upload(username, oauth_token, oauth_secret, title, body = nil, attachments = nil, options = { })
      raise "Please provide an oauth_token and an oauth_secret" if oauth_token.nil? || oauth_secret.nil?

      http_opts = prepare_http_opts(username, oauth_secret, oauth_token, options)
      post_data = prepare_post_data(nil, nil, title, body, attachments, options)

      # disables the annoying Expect header, which don't work wth Ping.fm's server
      http_opts[:headers]["Expect"] = nil

      update_url = "#{http_proto}://posterous.com/api2/upload.json"

      logger.debug "#{update_url} => #{post_data.inspect}"
      resp = HTTP.post(update_url, post_data, nil, http_opts)
      unless resp.nil? || resp.fail?
        parse_json_response(resp)
      else
        resp
      end
    end

    # Twitter compatible API
    def self.upload_and_post(username, password, title, body = nil, attachments = nil, options = { })
      raise "Please provide a password" if password.nil?

      http_opts = prepare_http_opts(username, password, nil, options)
      post_data = prepare_post_data(username, password, title, body, attachments, options)

      # disables the annoying Expect header, which don't work wth Ping.fm's server
      http_opts[:headers]["Expect"] = nil

      update_url = "#{http_proto}://posterous.com/api/uploadAndPost"

      logger.debug "#{update_url} => #{post_data.inspect}"
      resp = HTTP.post(update_url, post_data, nil, http_opts)
      unless resp.nil? || resp.fail?
        parse_response(resp)
      else
        resp
      end
    end

    protected

    def self.parse_json_response(resp)
# {
#      "id":"T8v",
#      "type":"png",
#      "timestamp":"Wed Jun 02 13:19:29 -0700 2010",
#      "text":"message",
#      "url":"http://post.ly/T8v",
#      "height":211,
#      "width":165,
#      "size":66,
#      "user":{
#           "screen_name":"l_pauling",
#           "id":21465735
#      }
# }
      json_resp = resp.json_read
      unless json_resp.include?('error')
        json_resp
      else
        raise PosporoFail.new("Error reply: #{json_resp['error']}", resp)
      end
    end

    def self.parse_response(resp)
      xml_d = resp.xml_read
      unless xml_d.nil?
        xml_resp = xml_d.find("/rsp").first
        unless xml_resp.nil?
          if xml_resp.attributes['stat'] == 'ok'
            xml_mediaid = xml_d.find("/rsp/mediaid").first
            xml_mediaurl = xml_d.find("/rsp/mediaurl").first

            unless xml_mediaid.nil?
              { :mediaid => xml_mediaid.content,
                :mediaurl => xml_mediaurl.content }
            else
              raise PosporoFail.new("Returned ok, but could not retrieve created media id")
            end
          else
            xml_error = xml_d.find("/rsp/err").first
            unless xml_error.empty?
              error_code = xml_error.attributes['code']
              error_msg = xml_error.attributes['msg']

              raise PosporoFail.new("Failed with #{error_code}, #{error_msg}", resp)
            else
              raise PosporoFail.new("Unknown error with #{xml_resp.attributes['stat']}", resp)
            end
          end
        else
          raise PosporoFail.new("Unknown XML format: #{xml_d}", resp)
        end
      else
        raise PosporoFail.new("Unable to parse XML response", resp)
      end
    end

    def self.prepare_http_opts(username, password, oauth_token = nil, options = { })
      http_opts = { :headers => { } }
      add_user_agent(http_opts)

      # add oauth echo authorization, if provided
      unless oauth_token.nil?
        add_authorization(http_opts, username, oauth_token, password)
        options[:use_oauth_echo] = true
      end

      http_opts
    end

    def self.add_authorization(http_opts, username, oauth_token, oauth_secret)
      http_opts[:headers]['X-Auth-Service-Provider'] = Twitow.oauth_echo_provider

      echo_authorization = Twitow.oauth_echo(username, oauth_token, oauth_secret)
      http_opts[:headers]['X-Verify-Credentials-Authorization'] = echo_authorization
    end

    def self.add_user_agent(http_opts)
      unless user_agent.nil?
        http_opts[:headers]["User-Agent"] = user_agent
      end
    end

    # TODO: attachments are not yet supported
    def self.prepare_post_data(username, password, title, body, attachments, options = { })

      unless options.include?(:source)
        options[:source] = "candy_wrapper"
      end

      unless options.include?(:source_link)
        options[:source_link] = "http://github.com/markjeee/candy_wrapper"
      end

      post_data = { }
      unless options.include?(:use_oauth_echo) || username.nil? || password.nil?
        post_data[:username] = username
        post_data[:password] = password
      end

      post_data.merge({
        :message => title,
        :body => body,
        :source => options[:source],
        :sourceLink => options[:source_link]
      })
    end
  end
end
