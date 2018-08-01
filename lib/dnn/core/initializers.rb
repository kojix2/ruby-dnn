module DNN
  module Initializers

    class Initializer
      def init_param(layer, param_key, param)
        layer.params[param_key] = param
      end

      def to_hash(merge_hash = nil)
        hash = {name: self.class.name}
        hash.merge!(merge_hash) if merge_hash
        hash
      end
    end


    class Zeros < Initializer
      def init_param(layer, param_key)
        super(layer, param_key, layer.params[param_key].fill(0))
      end
    end
    
    
    class RandomNormal < Initializer
      attr_reader :mean
      attr_reader :std
      
      def self.load_hash(hash)
        self.new(hash[:mean], hash[:std])
      end

      def initialize(mean = 0, std = 0.05)
        @mean = mean
        @std = std
      end

      def init_param(layer, param_key)
        super(layer, param_key, layer.params[param_key].rand_norm(@mean, @std))
      end

      def to_hash
        super({mean: @mean, std: @std})
      end
    end
    
    
    class Xavier < Initializer
      def init_param(layer, param_key)
        prev_dim = layer.prev_layer.shape.reduce(:*)
        super(layer, param_key, layer.params[param_key].rand_norm / Math.sqrt(prev_dim))
      end
    end
    
    
    class He < Initializer
      def init_param(layer, param_key)
        prev_dim = layer.prev_layer.shape.reduce(:*)
        super(layer, param_key, layer.params[param_key].rand_norm / Math.sqrt(prev_dim) * Math.sqrt(2))
      end
    end

  end
end
