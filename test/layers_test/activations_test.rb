require "test_helper"

class TestSigmoid < MiniTest::Unit::TestCase
  def test_forward_node
    sigmoid = DNN::Layers::Sigmoid.new
    y = sigmoid.forward_node(Xumo::SFloat[0, 1])
    assert_equal Xumo::SFloat[0.5, 0.7311], y.round(4)
  end

  def test_backward_node
    sigmoid = DNN::Layers::Sigmoid.new
    x = Xumo::SFloat[0, 1]
    sigmoid.forward_node(x)
    grad = sigmoid.backward_node(1)
    assert_equal Xumo::SFloat[0.25, 0.1966], grad.round(4)
  end

  def test_backward_node2
    sigmoid = DNN::Layers::Sigmoid.new
    x = Xumo::DFloat[0, 1]
    sigmoid.forward_node(x)
    grad = sigmoid.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, sigmoid.method(:forward_node)).round(4), grad.round(4)
  end
end

class TestTanh < MiniTest::Unit::TestCase
  def test_forward_node
    tanh = DNN::Layers::Tanh.new
    y = tanh.forward_node(Xumo::SFloat[0, 1])
    assert_equal Xumo::SFloat[0, 0.7616], y.round(4)
  end

  def test_backward_node
    tanh = DNN::Layers::Tanh.new
    x = Xumo::SFloat[0, 1]
    tanh.forward_node(x)
    grad = tanh.backward_node(1)
    assert_equal Xumo::SFloat[1, 0.42], grad.round(4)
  end

  def test_backward_node2
    tanh = DNN::Layers::Tanh.new
    x = Xumo::DFloat[0, 1]
    tanh.forward_node(x)
    grad = tanh.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, tanh.method(:forward_node)).round(4), grad.round(4)
  end
end

class TestSoftsign < MiniTest::Unit::TestCase
  def test_forward_node
    softsign = DNN::Layers::Softsign.new
    y = softsign.forward_node(Xumo::SFloat[0, 1])
    assert_equal Xumo::SFloat[0, 0.5], y.round(4)
  end

  def test_backward_node
    softsign = DNN::Layers::Softsign.new
    x = Xumo::SFloat[0, 1]
    softsign.forward_node(x)
    grad = softsign.backward_node(1)
    assert_equal Xumo::SFloat[1, 0.25], grad.round(4)
  end

  def test_backward_node2
    softsign = DNN::Layers::Softsign.new
    x = Xumo::DFloat[0, 1]
    softsign.forward_node(x)
    grad = softsign.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, softsign.method(:forward_node)).round(4), grad.round(4)
  end
end

class TestSoftplus < MiniTest::Unit::TestCase
  def test_forward_node
    softplus = DNN::Layers::Softplus.new
    y = softplus.forward_node(Xumo::SFloat[0, 1])
    assert_equal Xumo::SFloat[0.6931, 1.3133], y.round(4)
  end

  def test_backward_node
    softplus = DNN::Layers::Softplus.new
    x = Xumo::SFloat[0, 1]
    softplus.forward_node(x)
    grad = softplus.backward_node(1)
    assert_equal Xumo::SFloat[0.5, 0.7311], grad.round(4)
  end

  def test_backward_node2
    softplus = DNN::Layers::Softplus.new
    x = Xumo::DFloat[0, 1]
    softplus.forward_node(x)
    grad = softplus.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, softplus.method(:forward_node)).round(4), grad.round(4)
  end
end

class TestSwish < MiniTest::Unit::TestCase
  def test_forward_node
    swish = DNN::Layers::Swish.new
    y = swish.forward_node(Xumo::SFloat[0, 1])
    assert_equal Xumo::SFloat[0, 0.7311], y.round(4)
  end

  def test_backward_node
    swish = DNN::Layers::Swish.new
    x = Xumo::SFloat[0, 1]
    swish.forward_node(x)
    grad = swish.backward_node(1)
    assert_equal Xumo::SFloat[0.5, 0.9277], grad.round(4)
  end

  def test_backward_node2
    swish = DNN::Layers::Swish.new
    x = Xumo::DFloat[0, 1]
    swish.forward_node(x)
    grad = swish.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, swish.method(:forward_node)).round(4), grad.round(4)
  end
end

class TestReLU < MiniTest::Unit::TestCase
  def test_forward_node
    relu = DNN::Layers::ReLU.new
    y = relu.forward_node(Xumo::SFloat[-2, 0, 2])
    assert_equal Xumo::SFloat[0, 0, 2], y
  end

  def test_backward_node
    relu = DNN::Layers::ReLU.new
    relu.forward_node(Xumo::SFloat[-2, 0, 2])
    grad = relu.backward_node(1)
    assert_equal Xumo::SFloat[0, 0, 1], grad.round(4)
  end
end

class TestLeakyReLU < MiniTest::Unit::TestCase
  def test_from_hash
    hash = { class: "DNN::Layers::LeakyReLU", alpha: 0.2 }
    lrelu = DNN::Layers::LeakyReLU.from_hash(hash)
    assert_equal 0.2, lrelu.alpha
  end

  def test_initialize
    lrelu = DNN::Layers::LeakyReLU.new
    assert_equal 0.3, lrelu.alpha
  end

  def test_forward_node
    lrelu = DNN::Layers::LeakyReLU.new
    y = lrelu.forward_node(Xumo::SFloat[-2, 0, 2])
    assert_equal Xumo::SFloat[-0.6, 0, 2], y.round(4)
  end

  def test_backward_node
    lrelu = DNN::Layers::LeakyReLU.new
    lrelu.forward_node(Xumo::SFloat[-2, 0, 2])
    grad = lrelu.backward_node(1)
    assert_equal Xumo::SFloat[0.3, 0.3, 1], grad.round(4)
  end

  def test_backward_node2
    lrelu = DNN::Layers::LeakyReLU.new
    x = Xumo::DFloat[-2, 1, 2]
    lrelu.forward_node(x)
    grad = lrelu.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, lrelu.method(:forward_node)).round(4), Xumo::DFloat.cast(grad).round(4)
  end

  def test_to_hash
    lrelu = DNN::Layers::LeakyReLU.new
    expected_hash = { class: "DNN::Layers::LeakyReLU", alpha: 0.3 }
    assert_equal expected_hash, lrelu.to_hash
  end
end

class TestELU < MiniTest::Unit::TestCase
  def test_from_hash
    hash = { class: "DNN::Layers::ELU", alpha: 0.2 }
    elu = DNN::Layers::ELU.from_hash(hash)
    assert_equal 0.2, elu.alpha
  end

  def test_initialize
    elu = DNN::Layers::ELU.new
    assert_equal 1.0, elu.alpha
  end

  def test_forward_node
    elu = DNN::Layers::ELU.new
    y = elu.forward_node(Xumo::SFloat[-2, 0, 2])
    assert_equal Xumo::SFloat[-0.8647, 0, 2], y.round(4)
  end

  def test_backward_node
    elu = DNN::Layers::ELU.new
    elu.forward_node(Xumo::SFloat[-2, 0, 2])
    grad = elu.backward_node(1)
    assert_equal Xumo::SFloat[0.1353, 1, 1], grad.round(4)
  end

  def test_backward_node2
    elu = DNN::Layers::ELU.new
    x = Xumo::DFloat[-2, 1, 2]
    elu.forward_node(x)
    grad = elu.backward_node(1)
    assert_equal DNN::Utils.numerical_grad(x, elu.method(:forward_node)).round(4), grad.round(4)
  end

  def test_to_hash
    elu = DNN::Layers::ELU.new
    expected_hash = { class: "DNN::Layers::ELU", alpha: 1.0 }
    assert_equal expected_hash, elu.to_hash
  end

  class TestMish < MiniTest::Unit::TestCase
    def test_forward_node
      mish = DNN::Layers::Mish.new
      y = mish.forward_node(Xumo::SFloat[0, 1])
      assert_equal Xumo::SFloat[0, 0.8651], y.round(4)
    end
  
    def test_backward_node
      mish = DNN::Layers::Mish.new
      x = Xumo::SFloat[0, 1]
      mish.forward_node(x)
      grad = mish.backward_node(1)
      assert_equal Xumo::SFloat[0.6, 1.049], grad.round(4)
    end

    def test_backward_node2
      mish = DNN::Layers::Mish.new
      x = Xumo::DFloat[0, 1]
      mish.forward_node(x)
      grad = mish.backward_node(1)
      assert_equal DNN::Utils.numerical_grad(x, mish.method(:forward_node)).round(4), grad.round(4)
    end
  end
end
