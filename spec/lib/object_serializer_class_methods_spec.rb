require 'spec_helper'

RSpec.describe FastJsonapi::ObjectSerializer do
  include_context 'movie class'

  describe '#has_many' do
    subject(:relationship) { serializer.relationships_to_serialize[:roles] }

    before do
      serializer.has_many(*children)
    end

    after do
      serializer.relationships_to_serialize = {}
    end

    context 'with namespace' do
      before do
        class AppName::V1::RoleSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:serializer) { AppName::V1::MovieSerializer }
      let(:children) { [:roles] }
      let(:relationship_serializer) { AppName::V1::RoleSerializer }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :role_ids, :role
      end
    end

    context 'without namespace' do
      before do
        class RoleSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:serializer) { MovieSerializer }
      let(:relationship_serializer) { RoleSerializer }

      context 'with overrides' do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like 'returning correct relationship hash', :roles_only_ids, :super_role
      end

      context 'without overrides' do
        let(:children) { [:roles] }

        it_behaves_like 'returning correct relationship hash', :role_ids, :role
      end
    end
  end

  describe '#has_many with block' do
    before do
      MovieSerializer.has_many :awards do |movie|
        movie.actors.map(&:awards).flatten
      end
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:awards)
    end

    context 'awards is not included' do
      subject(:hash) { MovieSerializer.new(movie).serializable_hash }

      it 'returns correct hash' do
        expect(hash[:data][:relationships][:awards][:data].length).to eq(6)
        expect(hash[:data][:relationships][:awards][:data][0]).to eq({ id: '9', type: :award })
        expect(hash[:data][:relationships][:awards][:data][-1]).to eq({ id: '28', type: :award })
      end
    end

    context 'state is included' do
      subject(:hash) { MovieSerializer.new(movie, include: [:awards]).serializable_hash }

      it 'returns correct hash' do
        expect(hash[:included].length).to eq 6
        expect(hash[:included][0][:id]).to eq '9'
        expect(hash[:included][0][:type]).to eq :award
        expect(hash[:included][0][:attributes]).to eq({ id: 9, title: 'Test Award 9' })
        expect(hash[:included][0][:relationships]).to eq({ actor: { data: { id: '1', type: :actor } } })
        expect(hash[:included][-1][:id]).to eq '28'
        expect(hash[:included][-1][:type]).to eq :award
        expect(hash[:included][-1][:attributes]).to eq({ id: 28, title: 'Test Award 28' })
        expect(hash[:included][-1][:relationships]).to eq({ actor: { data: { id: '3', type: :actor } } })
      end
    end
  end

  describe '#has_many with block and id_method_name' do
    before do
      MovieSerializer.has_many(:awards, id_method_name: :imdb_award_id) do |movie|
        movie.actors.map(&:awards).flatten
      end
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:awards)
    end

    context 'awards is not included' do
      subject(:hash) { MovieSerializer.new(movie).serializable_hash }

      it 'returns correct hash where id is obtained from the method specified via `id_method_name`' do
        expected_award_data = movie.actors.map(&:awards).flatten.map do |actor|
          { id: actor.imdb_award_id.to_s, type: actor.class.name.downcase.to_sym }
        end
        serialized_award_data = hash[:data][:relationships][:awards][:data]

        expect(serialized_award_data).to eq(expected_award_data)
      end
    end
  end

  describe '#has_many with &:proc' do
    before do
      MovieSerializer.has_many :stars, &:actors
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:stars)
    end

    subject(:hash) { MovieSerializer.new(movie).serializable_hash }

    it 'returns correct hash' do
      expect(hash[:data][:relationships][:stars][:data].length).to eq(3)
      expect(hash[:data][:relationships][:stars][:data][0]).to eq({ id: '1', type: :actor })
      expect(hash[:data][:relationships][:stars][:data][1]).to eq({ id: '2', type: :actor })
      expect(hash[:data][:relationships][:stars][:data][2]).to eq({ id: '3', type: :actor })
    end
  end

  describe '#belongs_to' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.belongs_to(*parent)
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context 'with overrides' do
      before do
        class MyAreaSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:parent) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }
      let(:relationship_serializer) { MyAreaSerializer }

      it_behaves_like 'returning correct relationship hash', :blah_id, :awesome_area
    end

    context 'without overrides' do
      before do
        class AreaSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:parent) { [:area] }
      let(:relationship_serializer) { AreaSerializer }

      it_behaves_like 'returning correct relationship hash', :area_id, :area
    end
  end

  describe '#belongs_to with block' do
    before do
      ActorSerializer.belongs_to :state do |actor|
        actor.agency.state
      end
    end

    after do
      ActorSerializer.relationships_to_serialize.delete(:actorc)
    end

    context 'state is not included' do
      subject(:hash) { ActorSerializer.new(actor).serializable_hash }

      it 'returns correct hash' do
        expect(hash[:data][:relationships][:state][:data]).to eq({ id: '1', type: :state })
      end
    end

    context 'state is included' do
      subject(:hash) { ActorSerializer.new(actor, include: [:state]).serializable_hash }

      it 'returns correct hash' do
        expect(hash[:included].length).to eq 1
        expect(hash[:included][0][:id]).to eq '1'
        expect(hash[:included][0][:type]).to eq :state
        expect(hash[:included][0][:attributes]).to eq({ id: 1, name: 'Test State 1' })
        expect(hash[:included][0][:relationships]).to eq({ agency: { data: [{ id: '432', type: :agency }] } })
      end
    end
  end

  describe '#belongs_to with &:proc' do
    before do
      MovieSerializer.belongs_to :user, &:owner
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:user)
    end

    subject(:hash) { MovieSerializer.new(movie).serializable_hash }

    it 'returns correct hash' do
      expect(hash[:data][:relationships][:user][:data]).to eq({ id: '3', type: :owner })
    end
  end

  describe '#has_one' do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.has_one(*partner)
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context 'with overrides' do
      before do
        class MyAreaSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:partner) { [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area] }
      let(:relationship_serializer) { MyAreaSerializer }

      it_behaves_like 'returning correct relationship hash', :blah_id, :awesome_area
    end

    context 'without overrides' do
      before do
        class AreaSerializer
          include FastJsonapi::ObjectSerializer
        end
      end

      let(:partner) { [:area] }
      let(:relationship_serializer) { AreaSerializer }

      it_behaves_like 'returning correct relationship hash', :area_id, :area
    end
  end

  describe '#has_one with &:proc' do
    before do
      MovieSerializer.has_one :user, &:owner
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:user)
    end

    subject(:hash) { MovieSerializer.new(movie).serializable_hash }

    it 'returns correct hash' do
      expect(hash[:data][:relationships][:user][:data]).to eq({ id: '3', type: :owner })
    end
  end

  describe '#set_id' do
    let(:params) { {} }
    subject(:serializable_hash) do
      MovieSerializer.new(resource, { params: params }).serializable_hash
    end

    context 'method name' do
      before do
        MovieSerializer.set_id :owner_id
      end

      after do
        MovieSerializer.set_id nil
      end

      context 'when one record is given' do
        let(:resource) { movie }

        it 'returns correct hash which id equals owner_id' do
          expect(serializable_hash[:data][:id].to_i).to eq movie.owner_id
        end
      end

      context 'when an array of records is given' do
        let(:resource) { build_movies(2) }

        it 'returns correct hash which id equals owner_id' do
          expect(serializable_hash[:data][0][:id].to_i).to eq movie.owner_id
          expect(serializable_hash[:data][1][:id].to_i).to eq movie.owner_id
        end
      end
    end

    context 'with block' do
      let(:params) { { prefix: 'movie' } }

      before do
        MovieSerializer.set_id do |record, params|
          "#{params[:prefix]}-#{record.owner_id}"
        end
      end

      after do
        MovieSerializer.set_id nil
      end

      context 'when one record is given' do
        let(:resource) { movie }

        it 'returns correct hash which id equals movie-id' do
          expect(serializable_hash[:data][:id]).to eq "movie-#{movie.owner_id}"
        end
      end

      context 'when an array of records is given' do
        let(:resource) { build_movies(2) }

        it 'returns correct hash which id equals movie-id' do
          expect(serializable_hash[:data][0][:id]).to eq "movie-#{movie.owner_id}"
          expect(serializable_hash[:data][1][:id]).to eq "movie-#{movie.owner_id}"
        end
      end
    end

    context 'with a lambda' do
      let(:params) { { prefix: 'movie' } }

      before do
        MovieSerializer.set_id ->(record) { "#{params[:prefix]}-#{record.owner_id}" }
      end

      after do
        MovieSerializer.set_id nil
      end

      let(:resource) { movie }

      it 'returns correct hash which id equals movie-id' do
        expect(serializable_hash[:data][:id]).to eq "movie-#{movie.owner_id}"
      end
    end
  end

  describe '#use_hyphen' do
    subject { MovieSerializer.use_hyphen }

    after do
      MovieSerializer.transform_method = nil
    end

    it 'sets the correct transform_method when use_hyphen is used' do
      warning_message = "DEPRECATION WARNING: use_hyphen is deprecated and will be removed from fast_jsonapi 2.0 use (set_key_transform :dash) instead\n"
      expect { subject }.to output(warning_message).to_stderr
      expect(MovieSerializer.instance_variable_get(:@transform_method)).to eq :dasherize
    end
  end

  describe '#attribute' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    context 'with block' do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :title_with_year do |record|
          "#{record.name} (#{record.release_year})"
        end
      end

      after do
        MovieSerializer.attributes_to_serialize.delete(:title_with_year)
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:attributes][:name]).to eq movie.name
        expect(serializable_hash[:data][:attributes][:title_with_year]).to eq "#{movie.name} (#{movie.release_year})"
      end
    end

    context 'with &:proc' do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :released_in_year, &:release_year
<<<<<<< HEAD
<<<<<<< HEAD
        MovieSerializer.attribute :name, &:local_name
=======
>>>>>>> 449c1bf... Allow passing procs with variable arguments when declaring an attribute
=======
        MovieSerializer.attribute :name, &:local_name
>>>>>>> e05193f... Add spec for proc methods with optional arguments
      end

      after do
        MovieSerializer.attributes_to_serialize.delete(:released_in_year)
        MovieSerializer.attributes_to_serialize.delete(:name)
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:attributes][:name]).to eq "english #{movie.name}"
        expect(serializable_hash[:data][:attributes][:released_in_year]).to eq movie.release_year
      end
    end

    context 'with lambda' do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :released_in_year, &:release_year
        MovieSerializer.attribute :name, ->(object) { object.local_name }
      end

      after do
        MovieSerializer.attributes_to_serialize.delete(:released_in_year)
        MovieSerializer.attributes_to_serialize.delete(:name)
      end

      it 'returns correct hash when serializable_hash is called' do
<<<<<<< HEAD
<<<<<<< HEAD
        expect(serializable_hash[:data][:attributes][:name]).to eq "english #{movie.name}"
=======
        expect(serializable_hash[:data][:attributes][:name]).to eq movie.name
>>>>>>> 449c1bf... Allow passing procs with variable arguments when declaring an attribute
=======
        expect(serializable_hash[:data][:attributes][:name]).to eq "english #{movie.name}"
>>>>>>> e05193f... Add spec for proc methods with optional arguments
        expect(serializable_hash[:data][:attributes][:released_in_year]).to eq movie.release_year
      end
    end
  end

  describe '#meta' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    context 'with block' do
      before do
        movie.release_year = 2008
        MovieSerializer.meta do |movie|
          {
            years_since_release: year_since_release_calculator(movie.release_year)
          }
        end
      end

      after do
        movie.release_year = nil
        MovieSerializer.meta_to_serialize = nil
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:meta]).to eq({ years_since_release: year_since_release_calculator(movie.release_year) })
      end
    end

    context 'with lambda' do
      before do
        movie.release_year = 2008
        MovieSerializer.meta ->(movie) { { years_since_release: year_since_release_calculator(movie.release_year) } }
      end

      after do
        movie.release_year = nil
        MovieSerializer.meta_to_serialize = nil
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:meta]).to eq({ years_since_release: year_since_release_calculator(movie.release_year) })
      end
    end

    private

    def year_since_release_calculator(release_year)
      Date.current.year - release_year
    end
  end

  describe '#link' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    after do
      MovieSerializer.data_links = {}
      ActorSerializer.data_links = {}
    end

    context 'with block calling instance method on serializer' do
      before do
        MovieSerializer.link(:self, &:url)
      end
      let(:url) { "http://movies.com/#{movie.id}" }

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:self]).to eq url
      end
    end

    context 'with block and param' do
      before do
        MovieSerializer.link(:public_url) do |movie_object|
          "http://movies.com/#{movie_object.id}"
        end
      end
      let(:url) { "http://movies.com/#{movie.id}" }

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:public_url]).to eq url
      end
    end

    context 'with method' do
      before do
        MovieSerializer.link(:object_id, :id)
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:object_id]).to eq movie.id
      end
    end

    context 'with method and convention' do
      before do
        MovieSerializer.link(:url)
      end

      it 'returns correct hash when serializable_hash is called' do
        expect(serializable_hash[:data][:links][:url]).to eq movie.url
      end
    end

    context 'when inheriting from a parent serializer' do
      subject(:action_serializable_hash) { ActionMovieSerializer.new(movie).serializable_hash }
      subject(:horror_serializable_hash) { HorrorMovieSerializer.new(movie).serializable_hash }

      it 'returns the link for the correct sub-class' do
        expect(action_serializable_hash[:data][:links][:url]).to eq "/action-movie/#{movie.id}"
      end
    end

    describe 'optional links' do
      subject(:downloadable_serializable_hash) { OptionalDownloadableMovieSerializer.new(movie, params).serializable_hash }

      context 'when the link is provided' do
        let(:params) { { params: { signed_url: signed_url } } }
        let(:signed_url) { 'http://example.com/download_link?signature=abcdef' }

        it 'includes the link' do
          expect(downloadable_serializable_hash[:data][:links][:download]).to eq signed_url
        end
      end

      context 'when the link is not provided' do
        let(:params) { { params: {} } }
        it 'does not include the link' do
          expect(downloadable_serializable_hash[:data][:links]).to_not have_key(:download)
        end
      end
    end

    describe 'optional links with a lambda' do
      subject(:downloadable_serializable_hash) { OptionalDownloadableMovieWithLambdaSerializer.new(movie).serializable_hash }

      context 'when the link should be provided' do
        before { movie.release_year = 2001 }

        it 'includes the link' do
          expect(downloadable_serializable_hash[:data][:links][:download]).to eq '/download/232'
        end
      end

      context 'when the link should not be provided' do
        before { movie.release_year = 1970 }

        it 'does not include the link' do
          expect(downloadable_serializable_hash[:data][:links]).to_not have_key(:download)
        end
      end
    end
  end

  describe '#key_transform' do
    subject(:hash) { movie_serializer_class.new(build_movies(2), include: [:movie_type]).serializable_hash }

    let(:movie_serializer_class) { "#{key_transform}_movie_serializer".classify.constantize }

    before(:context) do
      [:dash, :camel, :camel_lower, :underscore].each do |key_transform|
        movie_serializer_name = "#{key_transform}_movie_serializer".classify
        movie_type_serializer_name = "#{key_transform}_movie_type_serializer".classify
        # https://stackoverflow.com/questions/4113479/dynamic-class-definition-with-a-class-name
        movie_serializer_class = Object.const_set(movie_serializer_name, Class.new)
        # https://rubymonk.com/learning/books/5-metaprogramming-ruby-ascent/chapters/24-eval/lessons/67-instance-eval
        movie_serializer_class.instance_eval do
          include FastJsonapi::ObjectSerializer
          set_type :movie
          set_key_transform key_transform
          attributes :name, :release_year
          has_many :actors
          belongs_to :owner, record_type: :user
          belongs_to :movie_type, serializer: "#{key_transform}_movie_type".to_sym
        end
        movie_type_serializer_class = Object.const_set(movie_type_serializer_name, Class.new)
        movie_type_serializer_class.instance_eval do
          include FastJsonapi::ObjectSerializer
          set_key_transform key_transform
          attributes :name
        end
      end
    end

    context 'when key_transform is dash' do
      let(:key_transform) { :dash }

      it_behaves_like 'returning key transformed hash', :'movie-type', :'dash-movie-type', :'release-year'
    end

    context 'when key_transform is camel' do
      let(:key_transform) { :camel }

      it_behaves_like 'returning key transformed hash', :MovieType, :CamelMovieType, :ReleaseYear
    end

    context 'when key_transform is camel_lower' do
      let(:key_transform) { :camel_lower }

      it_behaves_like 'returning key transformed hash', :movieType, :camelLowerMovieType, :releaseYear
    end

    context 'when key_transform is underscore' do
      let(:key_transform) { :underscore }

      it_behaves_like 'returning key transformed hash', :movie_type, :underscore_movie_type, :release_year
    end
  end

  describe '#set_key_transform after #set_type' do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    before do
      MovieSerializer.set_type type_name
      MovieSerializer.set_key_transform :camel
    end

    after do
      MovieSerializer.transform_method = nil
      MovieSerializer.set_type :movie
    end

    context 'when sets singular type name' do
      let(:type_name) { :film }

      it 'returns correct hash which type equals transformed set_type value' do
        expect(serializable_hash[:data][:type]).to eq :Film
      end
    end

    context 'when sets plural type name' do
      let(:type_name) { :films }

      it 'returns correct hash which type equals transformed set_type value' do
        expect(serializable_hash[:data][:type]).to eq :Films
      end
    end
  end
end
