require 'test_helper'

describe Lotus::Model::Adapters::MongodbAdapter do
  before do
    Mongo::Logger.logger.level = 2
    Mongo::Client.new(DATABASE_URL)[collection].drop

    class DummyUser
      include Lotus::Entity
      attributes :name, :age, :created_at, :id
    end

    class DummyUserRepository
      include Lotus::Repository
    end
  end

  let(:mapper) do
    Lotus::Model::Mapper.new do
      collection :users do
        entity DummyUser

        attribute :id,   String
        attribute :name, String
        attribute :age,  Integer
        attribute :created_at, DateTime
      end
    end.load!
  end

  let(:collection) { :users }

  let(:adapter) do
    Lotus::Model::Adapters::MongodbAdapter.new(
      mapper, DATABASE_URL
    )
  end

  let(:entity) { DummyUser.new name: 'Yonderbound', age: 29, created_at: Time.now }
  let(:entity2) { DummyUser.new name: 'Yonderbound 2', age: 35, created_at: Time.now }

  describe '#create' do
    it 'stores the record' do
      adapter.create(collection, entity)
      refute_nil(entity.id)
      adapter.find(collection, entity.id).must_equal entity
    end
  end

  describe '#update' do
    it 'updates a stored record' do
      adapter.create(collection, entity)
      entity.name = 'test'
      adapter.update(collection, entity)
      adapter.find(collection, entity.id).name.must_equal 'test'
    end
  end

  describe '#delete' do
    it 'delete a stored record' do
      adapter.create(collection, entity)
      adapter.delete(collection, entity)
      adapter.find(collection, entity.id).must_equal nil
    end
  end

  describe '#all' do
    it 'all documents in a collection' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      documents = adapter.all(collection)
      documents.length.must_equal 2
    end
  end

  describe '#first' do
    it 'find the first document in a collection' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      adapter.first(collection).must_equal entity
    end

    it 'find the first document in a collection from query' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      adapter.query(collection) do
        limit(1)
      end.all.must_equal [entity]
    end
  end

  describe '#last' do
    it 'find the last document in a collection' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      adapter.last(collection).must_equal entity2
    end
  end

  describe '#clear' do
    it 'clear a collection' do
      adapter.create(collection, entity)
      adapter.create(collection, entity)
      adapter.clear(collection)
      adapter.last(collection).must_equal nil
    end
  end

  describe '#query' do
    it 'returns query object on find' do
      adapter.query(collection, DummyUserRepository.new) do
        obj = find(name: 'Yonderbound')
        obj.class.must_equal Lotus::Model::Adapters::Mongodb::Query
      end
    end

    it 'find a user from name' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      documents = adapter.query(collection, DummyUserRepository.new) do
        find(name: 'Yonderbound')
      end
      documents.count.must_equal 1
      documents.all.first.must_equal entity
    end

    it 'find a user from name and age' do
      adapter.create(collection, entity)
      adapter.create(collection, entity2)
      documents = adapter.query(collection, DummyUserRepository.new) do
        find(name: 'Yonderbound').find(age: 29)
      end

      documents.count.must_equal 1
      documents.all.first.must_equal entity
    end

    it 'find the first user from name and age' do
      adapter.create(collection, entity)
      adapter.create(collection, DummyUser.new(name: 'Yonderbound', age: 29, created_at: Time.now))
      documents = adapter.query(collection, DummyUserRepository.new) do
        find(name: 'Yonderbound').find(age: 29).limit(1)
      end

      documents.count.must_equal 1
      documents.all.first.must_equal entity
    end

    it 'find not existent user' do
      adapter.create(collection, entity)

      documents = adapter.query(collection, DummyUserRepository.new) do
        find(name: 'Yonderbound').find(age: 28).limit(1)
      end

      documents.count.must_equal 0
      documents.all.first.must_equal nil
    end

    it '#skip' do
      adapter.create(collection, entity)
      entity_dup = DummyUser.new(name: 'Yonderbound', age: 29, created_at: Time.now)
      adapter.create(collection, entity_dup)

      documents = adapter.query(collection, DummyUserRepository.new) do
        find(name: 'Yonderbound').find(age: 29).skip(1).limit(1)
      end

      documents.count.must_equal 1
      documents.all.first.must_equal entity_dup
    end
  end
end
