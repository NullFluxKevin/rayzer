require_relative 'distributor'


module Rayzer
  class Layout
    class RemainingSpaceError < ArgumentError; end

    using Distributor

    COLUMN_CONTAINER = :column_container
    ROW_CONTAINER = :row_container
    LEAF = :leaf

    attr_reader :x, :y, :width, :height, :parent, :children, :type


    def initialize(x, y, width, height, parent=nil)
      @x = x
      @y = y
      @width = width
      @height = height
      @parent = parent
      @children = []
      @type = LEAF
    end


    def root?
      @parent.nil?
    end


    def leaf?
      @type == LEAF
    end

    def rect
      [@x, @y, @width, @height]
    end


    def split_to_rows(constraints, names=nil, &block)
      heights = @height.distribute(*constraints)
      curr_y = @y
      @children = heights.map do |h|
        row = self.class.new(@x, curr_y, @width, h, self)
        curr_y += h
        row
      end

      constraints_size = constraints.size
      add_named_layout_instance_vars names, constraints_size
      add_remaining_instance_var constraints_size

      @type = ROW_CONTAINER
      yield @children if block_given?
      @children
    end


    def split_to_cols(constraints, names=nil, &block)
      widths = @width.distribute(*constraints)

      curr_x = @x

      @children = widths.map do |w|
        col = self.class.new(curr_x, @y, w, @height, self)
        curr_x += w
        col
      end

      constraints_size = constraints.size

      add_named_layout_instance_vars names, constraints_size
      add_remaining_instance_var constraints_size

      @type = COLUMN_CONTAINER
      yield @children if block_given?
      @children
    end


    def split_to_cols!(constraints, names=nil, &block)
      split_to_cols(constraints, names, &block)
      raise RemainingSpaceError if instance_variable_defined? :@remaining
      @children
    end


    def split_to_rows!(constraints, names=nil, &block)
      split_to_rows(constraints, names, &block)
      raise RemainingSpaceError if instance_variable_defined? :@remaining
      @children
    end


    def ==(other)
      # should require parent and children equality?
      return false unless @x == other.x
      return false unless @y == other.y
      return false unless @width == other.width
      return false unless @height == other.height
      true
    end


  private
    def add_named_layout_instance_vars(names, constraints_size)
      unless names.nil?
        if names.is_a? Array
          raise ArgumentError, "Size of names and size of constraints mismatch" unless names.size == constraints_size

          names.each.with_index do |name, i|
            next if name.nil?
            instance_variable_set "@#{name}", @children[i]
            define_singleton_method(name) { instance_variable_get "@#{name}" }
          end

        elsif names.is_a? Hash
          names.each do |i, name|
            instance_variable_set "@#{name}", @children.fetch(i)
            define_singleton_method(name) { instance_variable_get "@#{name}" }
          end

        else
          raise ArgumentError, "Invalid type for arg: names. Expecting Array or Hash"
        end
      end
    end


    def add_remaining_instance_var(constraints_size)
      if @children.size - constraints_size == 1
        instance_variable_set :@remaining, @children[-1]
        define_singleton_method(:remaining) { instance_variable_get :@remaining }
      end
    end


  end # end of layout
end # end of Rayzer
