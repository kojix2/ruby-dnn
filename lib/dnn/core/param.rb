module DNN
  class Param
    attr_accessor :tag
    attr_accessor :data
    attr_accessor :grad

    def initialize(data = nil, grad = nil)
      @data = data
      @grad = grad
      @tag = nil
    end
  end
end
