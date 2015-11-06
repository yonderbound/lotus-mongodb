require 'delegate'
require 'lotus/utils/kernel' unless RUBY_VERSION >= '2.1'

module Lotus
  module Model
    module Adapters
      module Mongodb
        # Maps a Mongodb collection and perfoms manipulations on it.
        #
        # @api private
        # @since 0.1.0
        #
        # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_basics_rdoc.html
        # @see http://sequel.jeremyevans.net/rdoc/files/doc/dataset_filtering_rdoc.html
        class Collection < SimpleDelegator
          def self.to_mongodb_id(id)
            BSON::ObjectId.legal?(id) ? BSON::ObjectId(id) : id
          end

          def initialize(dataset, mapped_collection)
            super(dataset)
            @mapped_collection = mapped_collection
          end

          # Creates a record for the given entity and assigns an id.
          #
          # @param entity [Object] the entity to persist
          #
          # @see Lotus::Model::Adapters::Mongodb::Command#create
          #
          # @return the primary key of the created record
          #
          # @api private
          # @since 0.1.0
          def insert(entity)
            id = BSON::ObjectId.new
            serialized_entity = _serialize(entity).merge('_id': id)
            insert_one(serialized_entity)
            entity.id = id.to_s
            entity
          end

          # Filters the current scope with a `find` directive.
          #
          # @param args [Array] the array of arguments
          #
          # @see Lotus::Model::Adapters::Mongodb::Query#find
          #
          # @return [Lotus::Model::Adapters::Mongodb::Collection] the filtered
          #   collection
          #
          # @api private
          # @since 0.1.0
          def find(*args)
            Collection.new(super, @mapped_collection)
          end

          # Updates the record corresponding to the given entity.
          #
          # @param entity [Object] the entity to persist
          #
          # @see Lotus::Model::Adapters::Sql::Command#update
          #
          # @api private
          # @since 0.1.0
          def update(entity)
            serialized_entity = _serialize(entity)
            update_one('$set' => serialized_entity)
            _deserialize(serialized_entity)
          end

          # Resolves self by fetching the records from the database and
          # translating them into entities.
          #
          # @return [Array] the result of the query
          #
          # @api private
          # @since 0.1.0
          def to_a
            deserialize(find)
          end

          # Name of the identity column in database
          #
          # @return [Symbol] the identity name
          #
          # @api private
          # @since 0.5.0
          def identity
            :id
          end

          # Serialize the given entity before to persist in the database.
          #
          # @return [Hash] the serialized entity
          #
          # @api private
          # @since 0.1.0
          def _serialize(entity)
            serialized = @mapped_collection.serialize(entity)
            serialized.delete(:id)
            serialized[:_id] = Collection.to_mongodb_id(entity.id) unless entity.id.nil?
            serialized
          end

          def deserialize(entities)
            entities.map do |record|
              item = Mapping::CollectionCoercer.new(@mapped_collection).from_record(record)
              item.id = record[:_id].to_s
              item
            end
          end

          # Deserialize the given entity after it was persisted in the database.
          #
          # @return [Lotus::Entity] the deserialized entity
          #
          # @api private
          # @since 0.2.2
          def _deserialize(entity)
            deserialize([entity])
          end
        end
      end
    end
  end
end
