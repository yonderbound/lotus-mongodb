require 'forwardable'
require 'lotus/utils/kernel'

module Lotus
  module Model
    module Adapters
      module Mongodb
        # Query the database with a powerful API.
        #
        # @example
        #
        #   query.find(language: 'ruby')
        #        .find(framework: 'lotus')
        #        .all
        #
        #   # the records are fetched only when we invoke #all
        #
        # It implements Ruby's `Enumerable` and borrows some methods from `Array`.
        # Expect a query to act like them.
        #
        class Query
          include Enumerable
          extend Forwardable

          def_delegators :all, :each, :to_s, :empty?

          attr_reader :conditions
          attr_reader :find_conditions

          # Initialize a query
          #
          # @param collection [Lotus::Model::Adapters::Mongodb::Collection] the
          #   collection to query
          #
          # @param blk [Proc] an optional block that gets yielded in the
          #   context of the current query
          #
          # @return [Lotus::Model::Adapters::Mongodb::Query]
          def initialize(collection, context = nil, &blk)
            @collection = collection
            @context = context
            @conditions = {}
            @find_conditions = {}

            instance_eval(&blk) if block_given?
          end

          # Resolves the query by fetching records from the database and
          # translating them into entities.
          #
          # @return [Array] a collection of entities
          #
          # @raise [Lotus::Model::InvalidQueryError] if there is some issue when
          # hitting the database for fetching records
          #
          def all
            run.to_a
          rescue StandardError => e
            raise Lotus::Model::InvalidQueryError.new(e.message)
          end

          def find(condition = nil)
            find_conditions.merge!(condition)
            self
          end

          alias_method :and, :find

          def limit(number)
            _push_to_conditions(:limit, number)
            self
          end

          def skip(number)
            _push_to_conditions(:skip, number)
            self
          end

          def order(*columns)
            conditions[_order_operator] = *columns
            self
          end
          alias_method :asc, :order

          def reverse_order(*columns)
            reversed_columns = columns.map { |c| { "#{c}".to_sym => -1 } }
            conditions[_order_operator] = reversed_columns.inject({}) { |r, s| r.merge!(s) } # .push([_order_operator, *reversed_columns])
            self
          end
          alias_method :desc, :reverse_order

          def exist?
            !count.zero?
          end

          def count
            run.count(conditions)
          end

          def scoped
            scope = @collection
            scope = scope.find(find_conditions, conditions)
            scope
          end
          alias_method :run, :scoped

          private

          def _push_to_conditions(condition_type, condition)
            fail ArgumentError.new('You need to specify a condition.') if condition.nil?
            conditions[condition_type] = condition
          end

          def _identity(_collection)
            :id
          end

          def _order_operator
            :sort
          end
        end
      end
    end
  end
end
