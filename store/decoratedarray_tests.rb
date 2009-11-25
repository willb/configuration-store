require 'decoratedarray'
require 'test/unit'


class DecoratedArrayTests < Test::Unit::TestCase
  def setup
    
  end

  def teardown

  end

  def test_initialize
    d = DecoratedArray.new
    assert_equal 0, d.size
  end

  def test_initialize_from_array
    arr = []
    0.upto(9) {|num| arr << num}

    d = DecoratedArray.new :contents=>arr

    assert_equal arr.size, d.size

    0.upto(9) {|num| assert_equal arr[num], d[num] }
  end

  def test_push
    d = DecoratedArray.new
    0.upto(9) do |num| 
      d << num
      assert_equal num+1,d.size
      assert_equal num,d[num]
    end
  end

  def test_set
    d = DecoratedArray.new
    0.upto(9) do |num| 
      d << num
    end

    d[4] = 42
    assert_equal 42, d[4]
  end

  def test_delete
    d = DecoratedArray.new
    0.upto(9) do |num| 
      d << num
    end
    
    orig_size = d.size
    d.delete(4)
    assert_equal orig_size-1,d.size
  end

  def test_decorate_push
    arr = []
    
    onpush = Proc.new do |val|
      arr << val
    end
    
    d = DecoratedArray.new :push_callback=>onpush
    0.upto(9) do |num| 
      d << num
      assert_equal d.size, arr.size
      assert_equal d[num], arr[num]
    end
  end
end
