require "dnn"
require "dnn/image"
require_relative "convnet8"

def load_model
  return if $model
  $model = ConvNet.create([28, 28, 1])
  $model.predict1(Numo::SFloat.zeros(28, 28, 1))
  $model.load_params("trained_mnist_params.marshal")
end

def mnist_predict(img, width, height)
  load_model
  img = Numo::UInt8.from_binary(img).reshape(width, height, 4)
  img = img[true, true, 0...3]
  img = DNN::Image.to_gray_scale(img)
  x = Numo::SFloat.cast(img) / 255
  out = $model.predict1(x)
  out.to_a.map { |v| v.round(4) * 100 }
end
