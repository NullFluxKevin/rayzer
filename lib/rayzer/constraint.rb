module Rayzer
  class Constraint
    # zero or one <=, >=, %, or :
    # (?<=) is a look ahead assertion, if matches < or >, then check for =
    # followed by digits
    # then optionally followed by a decimal point "." and digits
    @parse_arg_format_regex = /^([<>]?(?<=[<>])=|[%:])?\d+(.\d+)?$/
    
    FIXED = :fixed
    MINIMUM = :minimum
    MAXIMUM = :maximum
    PERCENTAGE = :percentage
    RATIO = :ratio

    # define factory class methods such as Constraint.fixed(value)
    constants.each do |constraint_type|
      define_singleton_method(constraint_type.downcase) do |value|
        new(const_get(constraint_type), value)
      end
    end


    attr_reader :type, :value


    def initialize(type, value)
      raise ArgumentError, "Negative constraint value: #{value}" if value.negative?
      @type = type
      @value = value
    end


    # This intends to provide a concise api for things that accepts constraints
    # 
    # Usage:
    #  To get a fixed constraint, pass:        30, "30", or :"30"
    #  To get a minimum constraint, pass:      ">=30", or :">=30"
    #  To get a percentage constraint, pass:   "30%", :"30%", "%30", :"%30" 
    #  To get a ratio constraint, pass:        ":30", or :":30"
    #  To get a maximum constraint, pass:      "<=30", or :"<=30"
    # 
    # 
    # API Usage Example:
    #   constraints = %i[ 3 20% <=10 >=5 :3 ] # or use %w
    #   constraints << Constraint.fixed(1)
    # 
    #   some_method(args)
    #  
    #   def some_method(args)
    #     constraints = args.map { |arg| Constraint.parse arg )
    #     ...
    #   end
    # 
    def self.parse(arg)

      is_of_valid_type = [Integer, Float, String, Symbol, self].any?{ |cls| arg.instance_of? cls }

      unless is_of_valid_type
        raise ArgumentError,
          "Cannot parse: #{arg}. Constraint.parse only accepts: Constraint, Integer, Float, Symbol and String of valid format" 
      end

      return arg.dup if arg.instance_of? self
      
      if [Integer, Float].include? arg.class
        return fixed arg
      end

      # I'm not making the regexp any more complex with look ahead assertion for checking % at the end only if the arg starts with a digit.
      if arg[-1] == "%"
        arg = "%" + arg[...-1]
      end

      raise ArgumentError, "Invalid argument format in: #{arg}" unless arg =~ @parse_arg_format_regex

      if arg[0] =~ /\d/
        value = parse_number arg
        return fixed value
      end

      case arg[0]
        when ">"
          value = parse_number arg[2..] # 2 == '>='.size
          minimum value
        when "%"
          value = parse_number arg[1..]
          percentage value
        when "<"
          value = parse_number arg[2..] # 2 == '<='.size
          maximum value
        when ":"
          value = parse_number arg[1..]
          ratio value
      end
    end
    

    def ==(other)
      (@type == other.type) && (@value == other.value)
    end


    private
      def self.parse_number(arg)
        arg = arg.to_s
        arg.include?(".") ? arg.to_f : arg.to_i
      end

  end # end of class

end # end of module
