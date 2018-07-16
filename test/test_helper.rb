$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "dnn"

require "minitest/autorun"

class Xumo::DFloat
  alias _round round
  def round(ndigits = nil)
    return self.map { |f| f.round(ndigits)} if ndigits
    _round
  end
end
