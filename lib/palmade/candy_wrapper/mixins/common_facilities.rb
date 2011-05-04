# -*- encoding: utf-8 -*-

module Palmade::CandyWrapper
  module Mixins
    module CommonFacilities
      HTTP = Palmade::CandyWrapper.http

      def self.extended(base)
        ce = <<CE
          @@ua = nil
          def self.user_agent=(ua); @@ua = ua; end
          def self.user_agent; @@ua; end

          @@logger = nil
          def self.logger=(l); @@logger = l; end
          def self.logger
            if @@logger.nil?
              @@logger = Palmade::CandyWrapper.logger
            else
              @@logger
            end
          end

          @@secure = true
          def self.secure=(s); @@secure = s; end
          def self.secure?; @@secure; end
CE
        base.class_eval(ce, __FILE__, __LINE__ + 1)
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

      def stringify_keys(h)
        h.inject({ }) do |o, (k,v)|
          o[k.to_s] = v
          o
        end
      end
    end
  end
end
