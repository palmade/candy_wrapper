module Posporo
  class PosporoFail < StandardError
    attr_reader :response

    def initialize(msg = nil, response = nil)
      super(msg)
      @response = response
    end
  end

  def self.logger=(l)
    @@logger = l
  end

  def self.logger
    if defined?(@@logger)
      @@logger
    else
      @@logger = Logger.new(STDOUT)
    end
  end

  def self.secure=(s)
    @@secure = s
  end

  def self.secure?
    @@secure ||= false
  end

  def self.http
    Palmade::Http
  end

  def self.http_proto
    secure? ? "https" : "http"
  end

  def self.upload_and_post(username, password, title, body = nil, attachments = nil, options = { })
    raise "Please provide either password or oauth access token" if password.nil?

    http_opts = prepare_http_opts(username, password, options)
    post_data = prepare_post_data(username, password, title, body, attachments, options)

    # disables the annoying Expect header, which don't work wth Ping.fm's server
    http_opts[:headers]["Expect"] = nil

    update_url = "#{http_proto}://posterous.com/api/uploadAndPost"

    logger.debug "#{update_url} => #{post_data.inspect}"
    resp = Palmade::Http.post(update_url, post_data, nil, http_opts)
    unless resp.nil? || resp.fail?
      parse_response(resp)
    else
      resp
    end
  end

  protected

  def self.parse_response(resp)
    xml_d = resp.xml_parse
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

  def self.prepare_http_opts(username, password, options = { })
    http_opts = { }
    http_opts[:headers] = { }
    http_opts
  end

  # TODO: attachments are not yet supported
  def self.prepare_post_data(username, password, title, body, attachments, options = { })

    unless options.include?(:source)
      options[:source] = "simpleteq"
    end

    unless options.include?(:source_link)
      options[:source_link] = "http://simpleteq.com"
    end

    { :username => username,
      :password => password,
      :message => title,
      :body => body,
      :source => options[:source],
      :sourceLink => options[:source_link] }
  end
end
