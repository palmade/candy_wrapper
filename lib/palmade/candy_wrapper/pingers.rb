# -*- coding: utf-8 -*-
require 'base64'

# TODO: !!!!!
# VERIFY IF THIS STILL WORKS WITH HTTP_SERVICE

module Palmade::CandyWrapper
  module Pingers
    HTTP = Palmade::HttpService::Http

    class PingFail < StandardError
      attr_reader :response

      def initialize(msg = nil, response = nil)
        super(msg)
        @response = response
      end
    end
    class PingNotRegistered < PingFail; end

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
      @@secure ||= false
    end

    def self.http_proto
      secure? ? "https" : "http"
    end

    def self.api_key
      if defined?(@@api_key)
        @@api_key
      else
        nil
      end
    end

    def self.api_key=(k)
      @@api_key = k
    end

    def self.post(app_key, body, post_method = "default", title = nil)
      # URL: http://api.ping.fm/v1/user.post
      #
      # Parameters:
      #  * api_key  – Your developer's API key
      #  * user_app_key – User’s application key
      #  * post_method – Posting method.  Either "default", "blog", "microblog" or "status."  Please refer to the section of this documentation that covers service method limitations.
      #  * body – Message body
      #
      # Optional parameters:
      #  * title – Title of the posted message.  This will only appear if the specified service supports a title field.  Otherwise, it will be discarded.  Title is required for "blog" post method.
      #  * service – A single service to post to.  This used to support multiple services separated by a comma.  Posting to multiple services has been deprecated as of June 2008.  Posting to a single service is still functional.
      #  * location – The user's current location.
      #  * tags – comma-separated list of tag words to include with the post.  i.e. "tag1,tag2"
      #  * mood – string literal mood.  i.e. "happy"
      #  * media – base64 encoded media data.
      #  * encoding – Set to "base64" to have the API decode before posting.  Useful when posting unicode or non URL encoded data.  If set, "title", "body", "location", "tags" and "mood" parameters are expected to be base64 encoded.
      #  * exclude – comma separated values of service IDs (IDs returned from user.services, user.triggers, user.latest and system.services) to exclude from the post.
      #  * debug – Set this value to "1" to avoid posting test data.
      #  * checksum – Set this variable to pass a data checksum to confirm that the posted data reaches the API server. Please read the section titled "Payload Checksums" above.
      #  * media_checksum –Set this variable to compare an MD5 checksum of image data being supplied with the post update.  Please read the subsection titled "Media Checksums" under the "Posting Media" section above.
      #
      # Example return:
      #
      #  <?xml version="1.0"?>
      #  <rsp status="OK">
      #    <transaction>12345</transaction>
      #    <method>user.post</method>
      #  </rsp>

      http_opts = { }
      http_opts[:headers] = { }

      # disables the annoying Expect header, which don't work wth Ping.fm's server
      http_opts[:headers]["Expect"] = nil

      post_data = prepare_post_data({ :user_app_key => app_key,
                                      :post_method => post_method,
                                      :encoding => 'base64',
                                      :body => Base64.encode64(body),
                                      :title => title.nil? ? nil : Base64.encode64(title) })

      url = "#{http_proto}://api.ping.fm/v1/user.post"

      logger.debug "#{url} => #{post_data.inspect}"
      resp = HTTP.post(url, post_data, nil, http_opts)
      unless resp.nil? || resp.fail?
        parse_response(resp)
      else
        resp
      end
    end

    def self.user_key(mobile_key)
      # http://api.ping.fm/v1/user.key
      #
      # Parameters:
      # * api_key - Your developer's API key
      # * mobile_key - Mobile application key. (Users can be prompted to get their key here: http://ping.fm/key/)
      #
      # Example return:
      #
      # <?xml version="1.0"?>
      # <rsp status="OK">
      # <transaction>12345</transaction>
      #   <method>user.key</method>
      #    <key>abcdeasdadsdghasdfaslkdjfa012345-1234567890</key>
      # </rsp>

      http_opts = { }
      post_data = prepare_post_data({ :mobile_key => mobile_key })
      url = "#{http_proto}://api.ping.fm/v1/user.key"

      logger.debug "#{url} => #{post_data.inspect}"
      resp = HTTP.post(url, post_data, nil, http_opts)
      unless resp.nil? || resp.fail?
        parse_response(resp, :key)
      else
        resp
      end
    end

    protected

    def self.parse_response(resp, *responses)
      xml_d = resp.xml_parse
      unless xml_d.nil?
        logger.debug "XML RESPONSE: #{xml_d}"

        xml_resp = xml_d.find("/rsp").first
        unless xml_resp.nil?
          if xml_resp.attributes['status'] == 'OK' # response status is OK
            xml_transaction = xml_d.find("/rsp/transaction").first
            xml_method = xml_d.find("/rsp/method").first

            unless xml_transaction.nil?
              parsed_r = { :transaction => xml_transaction.content,
                :method => xml_method.content }

              # let's retrieve the other requested responses
              unless responses.empty?
                responses.each do |r|
                  xml_r = xml_d.find("/rsp/#{r}").first
                  unless xml_r.nil?
                    parsed_r[r.to_sym] = xml_r.content
                  end
                end
              end

              parsed_r
            else
              raise PingFail.new("Returned ok, but could not retrieve created transaction id")
            end
          else # response status is probably FAIL
            xml_message = xml_d.find("/rsp/message").first

            unless xml_message.nil?
              error_msg = xml_message.content
              error_code = xml_resp.attributes['status']

              raise PingFail.new("Failed with #{error_code}, #{error_msg}", resp)
            else
              raise PingFail.new("Unknown error with #{xml_resp.attributes['status']}", resp)
            end
          end
        else
          raise PingFail.new("Unknown XML format: #{xml_d}", resp)
        end
      else
        raise PingFail.new("Unable to parse XML response", resp)
      end
    end

    # TODO: attachments are not yet supported
    def self.prepare_post_data(params = { })
      params = { }.update(params)

      unless params.include?(:api_key)
        if self.api_key.nil?
          raise "API key not specified (self.api_key is nil)"
        else
          params[:api_key] = self.api_key
        end
      end

      params
    end
  end
end
