class DecoratedArray < Array
  alias :array_push :push
  alias :array_delete :delete
  alias :array_set :[]=

    def initialize(options={})
    if options[:contents]
      super options[:contents]
    else
      super 0
    end
    
    @onpush = options[:push_callback]
    @ondelete = options[:delete_callback]
    @onset = options[:set_callback]
  end
  
  def push(val)
    @onpush.call(val) if @onpush
    array_push val
  end
  
  def <<(val)
    push val
  end
  
  def delete(val)
    @ondelete.call(val) if @ondelete
    array_delete val
  end
  
  def []=(pos, val)
    @onset.call(pos, val) if @onset
    array_set pos, val
  end
end
