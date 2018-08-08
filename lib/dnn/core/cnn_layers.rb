module DNN
  module Layers
    #This module is used for convolution.
    module Conv2DModule
      private

      def im2col(img, out_h, out_w, fil_h, fil_w, strides)
        bsize = img.shape[0]
        ch = img.shape[3]
        col = SFloat.zeros(bsize, ch, fil_h, fil_w, out_h, out_w)
        img = img.transpose(0, 3, 1, 2)
        (0...fil_h).each do |i|
          i_range = (i...(i + strides[0] * out_h)).step(strides[0]).to_a
          (0...fil_w).each do |j|
            j_range = (j...(j + strides[1] * out_w)).step(strides[1]).to_a
            col[true, true, i, j, true, true] = img[true, true, i_range, j_range]
          end
        end
        col.transpose(0, 4, 5, 2, 3, 1).reshape(bsize * out_h * out_w, fil_h * fil_w * ch)
      end

      def col2im(col, img_shape, out_h, out_w, fil_h, fil_w, strides)
        bsize, img_h, img_w, ch = img_shape
        col = col.reshape(bsize, out_h, out_w, fil_h, fil_w, ch).transpose(0, 5, 3, 4, 1, 2)
        img = SFloat.zeros(bsize, ch, img_h, img_w)
        (0...fil_h).each do |i|
          i_range = (i...(i + strides[0] * out_h)).step(strides[0]).to_a
          (0...fil_w).each do |j|
            j_range = (j...(j + strides[1] * out_w)).step(strides[1]).to_a
            img[true, true, i_range, j_range] += col[true, true, i, j, true, true]
          end
        end
        img.transpose(0, 2, 3, 1)
      end

      def padding(img, pad)
        bsize, img_h, img_w, ch = img.shape
        img2 = SFloat.zeros(bsize, img_h + pad[0], img_w + pad[1], ch)
        i_begin = pad[0] / 2
        i_end = i_begin + img_h
        j_begin = pad[1] / 2
        j_end = j_begin + img_w
        img2[true, i_begin...i_end, j_begin...j_end, true] = img
        img2
      end

      def back_padding(img, pad)
        i_begin = pad[0] / 2
        i_end = img.shape[1] - (pad[0] / 2.0).round
        j_begin = pad[1] / 2
        j_end = img.shape[2] - (pad[1] / 2.0).round
        img[true, i_begin...i_end, j_begin...j_end, true]
      end

      def out_size(prev_h, prev_w, fil_h, fil_w, strides)
        out_h = (prev_h - fil_h) / strides[0] + 1
        out_w = (prev_w - fil_w) / strides[1] + 1
        [out_h, out_w]
      end
    end
    
    
    class Conv2D < HasParamLayer
      include Initializers
      include Conv2DModule

      attr_reader :num_filters
      attr_reader :filter_size
      attr_reader :strides
      attr_reader :weight_decay
    
      def initialize(num_filters, filter_size,
                     weight_initializer: nil,
                     bias_initializer: nil,
                     strides: 1,
                     padding: false,
                     weight_decay: 0)
        super()
        @num_filters = num_filters
        @filter_size = filter_size.is_a?(Integer) ? [filter_size, filter_size] : filter_size
        @weight_initializer = (weight_initializer || RandomNormal.new)
        @bias_initializer = (bias_initializer || Zeros.new)
        @strides = strides.is_a?(Integer) ? [strides, strides] : strides
        @padding = padding
        @weight_decay = weight_decay
      end

      def self.load_hash(hash)
        Conv2D.new(hash[:num_filters], hash[:filter_size],
                   weight_initializer: Util.load_hash(hash[:weight_initializer]),
                   bias_initializer: Util.load_hash(hash[:bias_initializer]),
                   strides: hash[:strides],
                   padding: hash[:padding],
                   weight_decay: hash[:weight_decay])
      end

      def build(model)
        super
        prev_h, prev_w = prev_layer.shape[0..1]
        @out_size = out_size(prev_h, prev_w, *@filter_size, @strides)
        out_w, out_h = @out_size
        if @padding
          @pad = [prev_h - out_h, prev_w - out_w]
          @out_size = [prev_h, prev_w]
        end
      end

      def forward(x)
        x = padding(x, @pad) if @padding
        @x_shape = x.shape
        @col = im2col(x, *@out_size, *@filter_size, @strides)
        out = @col.dot(@params[:weight])
        out.reshape(x.shape[0], *@out_size, out.shape[3])
      end

      def backward(dout)
        dout = dout.reshape(dout.shape[0..2].reduce(:*), dout.shape[3])
        @grads[:weight] = @col.transpose.dot(dout)
        if @weight_decay > 0
          dridge = @weight_decay * @params[:weight]
          @grads[:weight] += dridge
        end
        @grads[:bias] = dout.sum(0)
        dcol = dout.dot(@params[:weight].transpose)
        dx = col2im(dcol, @x_shape, *@out_size, *@filter_size, @strides)
        @padding ? back_padding(dx, @pad) : dx
      end

      def shape
        [*@out_size, @num_filters]
      end

      def ridge
        if @weight_decay > 0
          0.5 * @weight_decay * (@params[:weight]**2).sum
        else
          0
        end
      end

      def to_hash
        super({num_filters: @num_filters,
               filter_size: @filter_size,
               weight_initializer: @weight_initializer.to_hash,
               bias_initializer: @bias_initializer.to_hash,
               strides: @strides,
               padding: @padding,
               weight_decay: @weight_decay})
      end
    
      private
    
      def init_params
        num_prev_filter = prev_layer.shape[2]
        @params[:weight] = SFloat.new(num_prev_filter * @filter_size.reduce(:*), @num_filters)
        @params[:bias] = SFloat.new(@num_filters)
        @weight_initializer.init_param(self, :weight)
        @bias_initializer.init_param(self, :bias)
      end
    end

    #Super class of all pooling2D class.
    class Pool2D < Layer
      include Conv2DModule

      attr_reader :pool_size
      attr_reader :strides

      def self.load_hash(pool2d_class, hash)
        pool2d_class.new(hash[:pool_size], strides: hash[:strides], padding: hash[:padding])
      end

      def initialize(pool_size, strides: nil, padding: false)
        super()
        @pool_size = pool_size.is_a?(Integer) ? [pool_size, pool_size] : pool_size
        @strides = if strides
          strides.is_a?(Integer) ? [strides, strides] : strides
        else
          @pool_size.clone
        end
        @padding = padding
      end

      def build(model)
        super
        prev_w, prev_h = prev_layer.shape[0..1]
        @num_channel = prev_layer.shape[2]
        @out_size = out_size(prev_h, prev_w, *@pool_size, @strides)
        out_w, out_h = @out_size
        if @padding
          @pad = [prev_h - out_h, prev_w - out_w]
          @out_size = [prev_h, prev_w]
        end
      end

      def forward(x)
        x = padding(x, @pad) if @padding
        @x_shape = x.shape
        col = im2col(x, *@out_size, *@pool_size, @strides)
        col.reshape(x.shape[0] * @out_size.reduce(:*) * x.shape[3], @pool_size.reduce(:*))
      end

      def backward(dcol)
        dx = col2im(dcol, @x_shape, *@out_size, *@pool_size, @strides)
        @padding ? back_padding(dx, @pad) : dx
      end

      def shape
        [*@out_size, @num_channel]
      end

      def to_hash
        super({pool_width: @pool_width,
               pool_height: @pool_height,
               strides: @strides,
               padding: @padding})
      end
    end
    
    
    class MaxPool2D < Pool2D
      def self.load_hash(hash)
        Pool2D.load_hash(self, hash)
      end

      def forward(x)
        col = super(x)
        @max_index = col.max_index(1)
        col.max(1).reshape(x.shape[0], *@out_size, x.shape[3])
      end

      def backward(dout)
        dmax = SFloat.zeros(dout.size * @pool_size.reduce(:*))
        dmax[@max_index] = dout.flatten
        dcol = dmax.reshape(dout.shape[0..2].reduce(:*), dout.shape[3] * @pool_size.reduce(:*))
        super(dcol)
      end
    end


    class AvgPool2D < Pool2D
      def self.load_hash(hash)
        Pool2D.load_hash(self, hash)
      end

      def forward(x)
        col = super(x)
        col.mean(1).reshape(x.shape[0], *@out_size, x.shape[3])
      end

      def backward(dout)
        row_length = @pool_size.reduce(:*)
        dout /= row_length
        davg = SFloat.zeros(dout.size, row_length)
        row_length.times do |i|
          davg[true, i] = dout.flatten
        end
        dcol = davg.reshape(dout.shape[0..2].reduce(:*), dout.shape[3] * @pool_size.reduce(:*))
        super(dcol)
      end
    end


    class UnPool2D < Layer
      attr_reader :unpool_size

      def initialize(unpool_size)
        super()
        @unpool_size = unpool_size.is_a?(Integer) ? [unpool_size, unpool_size] : unpool_size
      end

      def self.load_hash(hash)
        UnPool2D.new(hash[:unpool_size])
      end

      def build(model)
        super
        prev_h, prev_w = prev_layer.shape[0..1]
        unpool_h, unpool_w = @unpool_size
        out_h = prev_h * unpool_h
        out_w = prev_w * unpool_w
        @out_size = [out_h, out_w]
        @num_channel = prev_layer.shape[2]
      end

      def forward(x)
        @x_shape = x.shape
        unpool_h, unpool_w = @unpool_size
        x2 = SFloat.zeros(x.shape[0], x.shape[1], unpool_h, x.shape[2], unpool_w, @num_channel)
        x2[true, true, 0, true, 0, true] = x
        x2.reshape(x.shape[0], *@out_size, x.shape[3])
      end

      def backward(dout)
        unpool_h, unpool_w = @unpool_size
        dout = dout.reshape(dout.shape[0], @x_shape[0], unpool_h, @x_shape[1], unpool_w, @num_channel)
        dout[true, true, 0, true, 0, true].clone
      end

      def shape
        [@out_width, @out_height, @num_channel]
      end

      def to_hash
        super({unpool_size: @unpool_size})
      end
    end
  end
end