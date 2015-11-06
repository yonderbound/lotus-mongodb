require 'mongo'
require 'bson'
require 'lotus/model/adapters/abstract'
require 'lotus/model/adapters/implementation'
require 'lotus/model/adapters/mongodb/collection'
require 'lotus/model/adapters/mongodb/command'
require 'lotus/model/adapters/mongodb/query'
# require 'lotus/model/adapters/mongodb/collection_coercer'

module Lotus
  module Model
    module Adapters
      # Adapter for Mongodb databases
      #
      # In order to use it with a specific database, you must require the Ruby
      # gem before of loading Lotus::Model.
      #
      # @see Lotus::Model::Adapters::Implementation
      #
      # @api privat
      class MongodbAdapter < Abstract
        include Implementation
        include Mongo

        # Initialize the adapter.
        # @api private
        def initialize(mapper, uri)
          super
          @connection = Client.new(uri)
          @uri = uri
        rescue StandardError => e
          raise DatabaseAdapterNotFound.new(e.message)
        end

        # Creates a record in the database for the given entity.
        # It assigns the `id` attribute, in case of success.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        # @param entity [#id=] the entity to create
        #
        # @return [Object] the entity
        #
        # @api private
        def create(collection, entity)
          command(
            _collection(collection)
          ).create(entity)
        end

        # Updates a record in the database corresponding to the given entity.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        # @param entity [#id] the entity to update
        #
        # @return [Object] the entity
        #
        # @api private
        def update(collection, entity)
          command(
            _find(collection, entity.id)
          ).update(entity)
        end

        # Deletes a record in the database corresponding to the given entity.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        # @param entity [#id] the entity to delete
        #
        # @api private
        def delete(collection, entity)
          command(
            _find(collection, entity.id)
          ).delete
        end

        # Deletes all the records from the given collection.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        #
        # @api private
        def clear(collection)
          command(query(collection)).clear
        end

        # Fabricates a command for the given query.
        #
        # @param query [Lotus::Model::Adapters::Mongodb::Query] the query object to
        #   act on.
        #
        # @return [Lotus::Model::Adapters::Mongodb::Command]
        #
        # @see Lotus::Model::Adapters::Mongodb::Command
        #
        # @api private
        def command(query)
          Mongodb::Command.new(query)
        end

        # Fabricates a query
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        # @param blk [Proc] a block of code to be executed in the context of
        #   the query.
        #
        # @return [Lotus::Model::Adapters::Mongodb::Query]
        #
        # @see Lotus::Model::Adapters::Mongodb::Query
        #
        # @api private
        def query(collection, context = nil, &blk)
          Mongodb::Query.new(_collection(collection), context, &blk)
        end

        # Returns a string which can be executed to start a console suitable
        # for the configured database, adding the necessary CLI flags, such as
        # url, password, port number etc.
        #
        # @return [String]
        #
        # @since 0.3.0
        def connection_string
          @uri
        end

        # @api private
        # @since 0.5.0
        #
        # @see Lotus::Model::Adapters::Abstract#disconnect
        def disconnect
          # @connection.disconnect
          # @connection = DisconnectedResource.new
        end

        # Returns the first record in the given collection.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        #
        # @return [Object] the first entity
        #
        # @api private
        def first(collection)
          _first(
            query(collection).asc(:_id)
          )
        end

        # Returns the last record in the given collection.
        #
        # @param collection [Symbol] the target collection (it must be mapped).
        #
        # @return [Object] the last entity
        #
        # @api private
        def last(collection)
          _first(
            query(collection).desc(:_id)
          )
        end

        private

        def _find(collection, id)
          query(collection).find(_id: Mongodb::Collection.to_mongodb_id(id))
        end

        # Returns a collection from the given name.
        #
        # @param name [Symbol] a name of the collection (it must be mapped).
        #
        # @return [Lotus::Model::Adapters::Mongodb::Collection]
        #
        # @see Lotus::Model::Adapters::Mongodb::Collection
        #
        # @api private
        def _collection(name)
          Mongodb::Collection.new(@connection[name], _mapped_collection(name))
        end

        def _identity(_collection)
          :id
        end
      end
    end
  end
end
