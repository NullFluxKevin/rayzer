# Constraint Priority:
#   fixed = minimum > percentage > ratio > maximum
# 
# If there is still a remaining when every constraint is satisfied:
#   If there is a minimum constraint, then the remaining is added to the result of the first minimum constraint.
#   Otherwise:
#     If used distribute, the remaining is added to the end of the returned array
#     If used distribute!, raise an exception.

module Rayzer
  module Distributor
    refine Numeric do

      def distribute(*constraints)
        _distribute(constraints, false)
      end # end of distribute method 


      def distribute!(*constraints)
        # raises if the value is not completely distributed
        _distribute(constraints, true)
      end # end of distribute! method 


      private 
        def _distribute(args, raise_if_has_remaining)
          raise ArgumentError, "Can not distribute non-real value #{self}" unless [Integer, Float].include? self.class

          raise ArgumentError, "Can not distribute non-positive value #{self}" unless self.positive?

          constraints = args.map { |arg| Constraint.parse arg }

          remaining = self
          parts = Array.new(constraints.size) { 0 }
          first_min_index = nil

          total_percentage = 0
          percentages = []

          total_ratio = 0
          ratios = []

          maximums = []


          constraints.each.with_index do |cons, i|
            case cons.type
              when Constraint::FIXED, Constraint::MINIMUM
                parts[i] = cons.value
                remaining -= cons.value
                raise ArgumentError, "Sum of required constraints exceeds #{self}" if remaining < 0

                if cons.type == Constraint::MINIMUM
                  first_min_index = i if first_min_index.nil?
                end

              when Constraint::PERCENTAGE
                total_percentage += cons.value
                raise ArgumentError, "Sum of percentage constraints exceeds 100" if total_percentage > 100

                percentages << [i, cons.value]

              when Constraint::RATIO
                total_ratio += cons.value
                ratios << [i, cons.value]

              when Constraint::MAXIMUM
                maximums << [i, cons.value]
            end
          end


          unless remaining.zero? or total_percentage.zero?
            percentages.each do |i, percentage|
              parts[i] = percentage * 0.01 * remaining
            end

            remaining = (1 - total_percentage * 0.01) * remaining
          end


          unless remaining.zero? or total_ratio.zero?
            value_per_ratio = remaining.fdiv total_ratio

            ratios.each do |i, ratio|
              parts[i] = ratio * value_per_ratio
            end

            remaining = 0
          end


          maximums.each do |i, value|
            if value < remaining
              parts[i] = value 
              remaining -= value
            else
              parts[i] = remaining
              remaining = 0
              break
            end
          end


          unless remaining.zero?
            unless first_min_index.nil?
              parts[first_min_index] += remaining
              return parts
            end

            raise "Incomplete distribution of #{self}, remaining #{remaining}" if raise_if_has_remaining

            parts << remaining
          end

          
          parts
        end # end of _distribute method 

      # end of private

    end # end of refinement

  end # end of Distributor

end # end of Rayzer
