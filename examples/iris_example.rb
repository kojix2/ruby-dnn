require "dnn"
require "dnn/iris"
# If you use numo/linalg then please uncomment out.
# require "numo/linalg/autoloader"

include DNN::Layers
include DNN::Activations
include DNN::Optimizers
include DNN::Losses
include DNN::Models
Iris = DNN::Iris

x, y = Iris.load(true)
x_train, y_train = x[0...100, true], y[0...100]
x_test, y_test = x[100...150, true], y[100...150]

y_train = DNN::Utils.to_categorical(y_train, 3, Numo::SFloat)
y_test = DNN::Utils.to_categorical(y_test, 3, Numo::SFloat)

model = Sequential.new

model << InputLayer.new(4)

model << Dense.new(64)
model << ReLU.new

model << Dense.new(3)

model.setup(Adam.new, SoftmaxCrossEntropy.new)

model.train(x_train, y_train, 1000, batch_size: 10, test: [x_test, y_test])
