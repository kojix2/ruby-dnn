module DNN
  module Activations

    class Sigmoid < Layers::Layer
      def forward(x)
        @y = 1 / (1 + NMath.exp(-x))
      end
    
      def backward(dy)
        dy * (1 - @y) * @y
      end
    end


    class Tanh < Layers::Layer
      def forward(x)
        @y = NMath.tanh(x)
      end
      
      def backward(dy)
        dy * (1 - @y**2)
      end
    end


    class Softsign < Layers::Layer
      def forward(x)
        @x = x
        x / (1 + x.abs)
      end

      def backward(dy)
        dy * (1 / (1 + @x.abs)**2)
      end
    end


    class Softplus < Layers::Layer
      def forward(x)
        @x = x
        NMath.log(1 + NMath.exp(x))
      end

      def backward(dy)
        dy * (1 / (1 + NMath.exp(-@x)))
      end
    end


    class Swish < Layers::Layer
      def forward(x)
        @x = x
        @y = x * (1 / (1 + NMath.exp(-x)))
      end
    
      def backward(dy)
        dy * (@y + (1 / (1 + NMath.exp(-@x))) * (1 - @y))
      end
    end
    
    
    class ReLU < Layers::Layer
      def forward(x)
        @x = x.clone
        x[x < 0] = 0
        x
      end
    
      def backward(dy)
        @x[@x > 0] = 1
        @x[@x <= 0] = 0
        dy * @x
      end
    end


    class LeakyReLU < Layers::Layer
      attr_reader :alpha

      def initialize(alpha = 0.3)
        @alpha = alpha
      end

      def self.load_hash(hash)
        self.new(hash[:alpha])
      end

      def forward(x)
        @x = x.clone
        a = Xumo::SFloat.ones(x.shape)
        a[x <= 0] = @alpha
        x * a
      end

      def backward(dy)
        @x[@x > 0] = 1
        @x[@x <= 0] = @alpha
        dy * @x
      end

      def to_hash
        {class: self.class.name, alpha: alpha}
      end
    end


    class ELU < Layers::Layer
      attr_reader :alpha

      def self.load_hash(hash)
        self.new(hash[:alpha])
      end

      def initialize(alpha = 1.0)
        @alpha = alpha
      end

      def forward(x)
        @x = x
        x1 = Xumo::SFloat.zeros(x.shape)
        x1[x >= 0] = 1
        x1 *= x
        x2 = Xumo::SFloat.zeros(x.shape)
        x2[x < 0] = 1
        x2 *= @alpha * NMath.exp(x) - @alpha
        x1 + x2
      end

      def backward(dy)
        dx = Xumo::SFloat.ones(@x.shape)
        dx[@x < 0] = 0
        dx2 = Xumo::SFloat.zeros(@x.shape)
        dx2[@x < 0] = 1
        dx2 *= @alpha * NMath.exp(@x)
        dy * (dx + dx2)
      end

      def to_hash
        {class: self.class.name, alpha: @alpha}
      end
    end

  end
end
