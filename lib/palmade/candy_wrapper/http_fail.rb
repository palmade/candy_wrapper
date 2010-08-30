module Palmade::CandyWrapper
  class HttpFail < StandardError
    attr_reader :response

    def initialize(msg = nil, response = nil)
      super(msg)
      @response = response
    end
  end
end
