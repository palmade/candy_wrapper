# -*- encoding: utf-8 -*-

module Palmade::CandyWrapper
  module Mixins
    module CommonFacilities
      HTTP = Palmade::CandyWrapper.http

      def user_agent=(ua); @ua = ua; end
      def user_agent
        if defined?(@ua)
          @ua
        else
          nil
        end
      end

      def logger=(l); @logger = l; end
      def logger
        if defined?(@logger)
          @logger
        else
          @logger = Palmade::CandyWrapper.logger
        end
      end

      def secure=(s)
        @secure = s
      end

      def secure?
        @secure ||= true
      end

      def http_proto
        secure? ? "https" : "http"
      end

      def query_string(q)
        HTTP.query_string(q)
      end

      def urlencode(s)
        HTTP.urlencode(s)
      end

      def urldecode(s)
        HTTP.urldecode(s)
      end
    end
  end
end
