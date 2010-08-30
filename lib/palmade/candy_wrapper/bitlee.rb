# -*- encoding: utf-8 -*-

module Palmade::CandyWrapper
  module Bitlee
    HTTP = Palmade::CandyWrapper.http

    class BitleeFail < HttpFail; end

    extend Mixins::CommonFacilities
  end
end
