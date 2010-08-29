require 'logger'

module Palmade::CandyWrapper
  module Twitow
    UNAUTHORIZED_HTTP_CODES = [ 400, 401 ]
    DOWN_HTTP_CODES = [ 500, 502 ]

    TWITTER_API_SITE = "api.twitter.com".freeze
    TWITTER_API_VERSION = "1".freeze

    HTTP = Palmade::HttpService::Http
    HTTP_RESPONSE = Palmade::HttpService::Http::Response

    class TweetFail < StandardError
      attr_reader :response

      def initialize(msg = nil, response = nil)
        super(msg)
        @response = response
      end
    end

    class UnknownFail < TweetFail
      def initialize(msg = nil, response = nil)
        msg = "Unknown fail" if msg.nil?
        super(msg, response)
      end
    end

    class UnauthorizedFail < TweetFail
      def initialize(msg = nil, response = nil)
        msg = "Unauthorized fail" if msg.nil?
        super(msg, response)
      end
    end

    class WhaleFail < TweetFail
      def initialize(msg = nil, response = nil)
        msg = "Unauthorized fail" if msg.nil?
        super(msg, response)
      end
    end

    class Status
      attr_accessor :date
      attr_accessor :status_id
      attr_accessor :status
      attr_accessor :username
      attr_accessor :user_id

      def initialize(hd)
        parse!(hd)
      end

      def parse!(hd)
        self.date = Time.parse(hd['created_at']).utc
        self.status_id = hd['id'].to_s
        self.status = Twitow.urldecode(hd['text'].strip)
        self.username = hd['user']['screen_name']
        self.user_id = hd['user']['id'].to_s
      end

      def is_reply?
        if status =~ /^\@(\w+)\s+.*$/
          $~[1]
        else
          nil
        end
      end
    end

    class DM
      attr_accessor :dm_id
      attr_accessor :sender_id
      attr_accessor :sender
      attr_accessor :date
      attr_accessor :recipient_id
      attr_accessor :recipient
      attr_accessor :message

      def initialize(hd)
        parse!(hd)
      end

      def parse!(hd)
        self.dm_id = hd['id'].to_s
        self.sender_id = hd['sender_id'].to_s
        self.sender = hd['sender_screen_name']
        self.date = Time.parse(hd['created_at']).utc
        self.recipient_id = hd['recipient_id'].to_s
        self.recipient = hd['recipient_screen_name']
        self.message = Twitow.urldecode(hd['text'].strip)
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

    def self.secure=(s); @@secure = s; end
    def self.secure?; @@secure ||= true; end

    def self.tweet_fail!(resp, msg = nil)
      if resp.respond_to?(:http_response?) && resp.http_response?
        e = tweet_fail(resp, msg)
        raise e unless e.nil?
      else
        nil
      end
    end

    def self.tweet_fail(resp, msg = nil)
      if resp.success?
        nil
      else
        case resp.code.to_i
        when UNAUTHORIZED_HTTP_CODES
          UnauthorizedFail.new(msg, resp)
        when DOWN_HTTP_CODES
          WhaleFail.new(msg, resp)
        else
          UnknownFail.new(msg, resp)
        end
      end
    end

    def self.unauthorized?(resp)
      if resp.respond_to?(:http_response?) && resp.http_response?
        UNAUTHORIZED_HTTP_CODES.include?(resp.code.to_i)
      else
        nil
      end
    end

    def self.twitter_down?(resp)
      if resp.respond_to?(:http_response?) && resp.http_response?
        DOWN_HTTP_CODES.include?(resp.code.to_i)
      else
        nil
      end
    end

    def self.http_proto
      secure? ? "https".freeze : "http".freeze
    end

    def self.oauth_consumer(consumer_key = nil, consumer_secret = nil, nw = false)
      if consumer_key.nil?
        if defined?(@@oauth_consumer)
          if nw
            OAuth::Consumer.new(@@oauth_consumer.key,
                                @@oauth_consumer.secret,
                                :site => @@oauth_consumer.options[:site])
          else
            @@oauth_consumer
          end
        else
          nil
        end
      else
        oc = OAuth::Consumer.new(consumer_key,
                                 consumer_secret,
                                 :site => "#{http_proto}://#{TWITTER_API_SITE}".freeze)
        nw ? oc : (@@oauth_consumer = oc)
      end
    end

    def self.api_url(path)
      "#{http_proto}://#{TWITTER_API_SITE}/#{TWITTER_API_VERSION}/#{path}"
    end

    def self.get_request_token(callback = nil, authenticate = false)
      request_options = { }
      unless callback.nil?
        request_options[:oauth_callback] = callback
      end

      oc = oauth_consumer(nil, nil, true)
      oc.options[:authorize_path] = '/oauth/authenticate' if authenticate
      oc.get_request_token(request_options)
    end

    def self.get_access_token(request_token, verifier)
      access_options = { }
      access_options[:oauth_verifier] = verifier

      oc = oauth_consumer(nil, nil, true)
      oc.get_access_token(request_token, access_options)
    end

    def self.is_tsend_reply?(resp)
      resp.is_a?(Hash) && resp.include?('id') && resp.include?('text')
    end

    def self.tsend(username, status, password = nil, oauth_token = nil)
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      update_url = api_url("statuses/update.json")
      logger.debug { "#{update_url} => #{http_opts.inspect}" }

      status = "#{status[0,137]}..." if status.size > 140
      post_data = { :status => status }
      resp = HTTP.post(update_url, post_data, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read
      else
        resp
      end
    end

    def self.oauth_echo_provider
      api_url("account/verify_credentials.json")
    end

    def self.oauth_echo(username, oauth_token, oauth_secret)
      http_opts = create_http_opts(username, oauth_secret, oauth_token)

      HTTP.make_oauth_authorization(:get, api_url("account/verify_credentials.json"), http_opts)
    end

    def self.is_tverify_reply?(resp)
      resp.is_a?(Hash) && resp.include?('id') && resp.include?('screen_name')
    end

    def self.tverify(username, password = nil, oauth_token = nil)
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      verify_url = api_url("account/verify_credentials.json")
      logger.debug { "#{verify_url} => #{http_opts.inspect}" }

      resp = HTTP.get(verify_url, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read
      else
        resp
      end
    end

    def self.tmentions(username, password = nil, oauth_token = nil, query = { })
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      query[:count] = 50 unless query.include?(:count)

      mentions_url = api_url("statuses/mentions.json")
      unless query.empty?
        mentions_url += "?#{query_string(query)}"
      end

      logger.debug { "#{mentions_url} => #{http_opts.inspect}" }

      resp = HTTP.get(mentions_url, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read.compact.collect { |m| Status.new(m) }
      else
        resp
      end
    end

    def self.tfriends(username, password = nil, oauth_token = nil, query = { })
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      query[:count] = 50 unless query.include?(:count)

      friends_url = api_url("statuses/friends_timeline.json")
      unless query.empty?
        friends_url += "?#{query_string(query)}"
      end

      logger.debug { "#{friends_url} => #{http_opts.inspect}" }

      resp = HTTP.get(friends_url, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read.compact.collect { |m| Status.new(m) }
      else
        resp
      end
    end

    def self.tuser(username, password = nil, oauth_token = nil, query = { })
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      query[:count] = 50 unless query.include?(:count)

      user_url = api_url("statuses/user_timeline.json")
      unless query.empty?
        user_url += "?#{query_string(query)}"
      end

      logger.debug { "#{user_url} => #{http_opts.inspect}" }

      resp = HTTP.get(user_url, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read.collect { |m| Status.new(m) }
      else
        resp
      end
    end

    def self.tdms(username, password = nil, oauth_token = nil, query = { })
      raise "Please provide either password or oauth access tokens" if password.nil? && oauth_token.nil?
      http_opts = create_http_opts(username, password, oauth_token)

      query[:count] = 25 unless query.include?(:count)

      dms_url = api_url("direct_messages.json")
      unless query.empty?
        dms_url += "?#{query_string(query)}"
      end

      logger.debug { "#{dms_url} => #{http_opts.inspect}" }

      resp = HTTP.get(dms_url, nil, http_opts)
      unless resp.nil? || resp.fail?
        resp.json_read.collect { |dm| DM.new(dm) }
      else
        resp
      end
    end

    def self.create_http_opts(username, password, oauth_token = nil)
      http_opts = { :headers => { } }
      add_authentication(http_opts, username, password, oauth_token)
      add_user_agent(http_opts)
      http_opts
    end

    def self.add_authentication(http_opts, username, password, oauth_token = nil)
      if oauth_token.nil?
        http_opts[:basic_auth] = [ username, password ]
      else
        http_opts[:oauth_consumer] = oauth_consumer
        http_opts[:oauth_token] = OAuth::Token.new(oauth_token, password)
      end
    end

    def self.add_user_agent(http_opts)
      unless user_agent.nil?
        http_opts[:headers]["User-Agent"] = user_agent
      end
    end

    def self.query_string(q)
      HTTP.query_string(q)
    end

    def self.urlencode(s)
      HTTP.urlencode(s)
    end

    def self.urldecode(s)
      HTTP.urldecode(s)
    end
  end
end
