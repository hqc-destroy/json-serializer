RSpec.shared_context 'movie class' do
  # Movie, Actor Classes and serializers
  before(:context) do
    # models
    class Movie
      attr_accessor :id,
                    :name,
                    :release_year,
                    :director,
                    :actor_ids,
                    :owner_id,
                    :movie_type_id

      def actors
        actor_ids.map.with_index do |id, i|
          a = Actor.new
          a.id = id
          a.name = "Test #{a.id}"
          a.email = "test#{a.id}@test.com"
          a.agency_id = i
          a
        end
      end

      def movie_type
        mt = MovieType.new
        mt.id = movie_type_id
        mt.name = 'Episode'
        mt.movie_ids = [id]
        mt
      end

      def advertising_campaign_id
        1
      end

      def advertising_campaign
        ac = AdvertisingCampaign.new
        ac.id = 1
        ac.movie_id = id
        ac.name = "Movie #{name} is incredible!!"
        ac
      end

      def owner
        return unless owner_id

        ow = Owner.new
        ow.id = owner_id
        ow
      end

      def cache_key
        id.to_s
      end

      def local_name(locale = :english)
        "#{locale} #{name}"
      end

      def url
        "http://movies.com/#{id}"
      end

      def actors_relationship_url
        "#{url}/relationships/actors"
      end
    end

    class Actor
      attr_accessor :id, :name, :email, :agency_id

      def agency
        Agency.new.tap do |a|
          a.id = agency_id
          a.name = "Test Agency #{agency_id}"
          a.state_id = 1
        end
      end

      def awards
        award_ids.map do |i|
          Award.new.tap do |a|
            a.id = i
            a.title = "Test Award #{i}"
            a.actor_id = id
<<<<<<< HEAD
            a.year = 1990 + i
=======
            a.imdb_award_id = i * 10
>>>>>>> 9c65983... Evaluate ids via the specified ‘id_method_name’ when relationships are evaluated via a block
          end
        end
      end

      def award_ids
        [id * 9, id * 9 + 1]
      end

      def url
        "http://movies.com/actors/#{id}"
      end
    end

    class AdvertisingCampaign
      attr_accessor :id, :name, :movie_id
    end

    class Agency
      attr_accessor :id, :name, :state_id

      def state
        State.new.tap do |s|
          s.id = state_id
          s.name = "Test State #{state_id}"
          s.agency_ids = [id]
        end
      end
    end

    class Award
<<<<<<< HEAD
      attr_accessor :id, :title, :actor_id, :year
=======
      attr_accessor :id, :title, :actor_id, :imdb_award_id
>>>>>>> 9c65983... Evaluate ids via the specified ‘id_method_name’ when relationships are evaluated via a block
    end

    class State
      attr_accessor :id, :name, :agency_ids
    end

    class MovieType
      attr_accessor :id, :name, :movie_ids

      def movies
        movie_ids.map.with_index do
          m = Movie.new
          m.id = 232
          m.name = 'test movie'
          m.actor_ids = [1, 2, 3]
          m.owner_id = 3
          m.movie_type_id = 1
          m
        end
      end
    end

    class Agency
      attr_accessor :id, :name, :actor_ids
    end

    class Agency
      attr_accessor :id, :name, :actor_ids
    end

    class Supplier
      attr_accessor :id, :account_id
    end

    class Account
      attr_accessor :id
    end

    class Owner
      attr_accessor :id
    end

    class OwnerSerializer
      include FastJsonapi::ObjectSerializer
    end

    # serializers
    class MovieSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      # director attr is not mentioned intentionally
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user do |object, _params|
        object.owner
      end
      belongs_to :movie_type
      has_one :advertising_campaign
    end

    class GenreMovieSerializer < MovieSerializer
      link(:something) { '/something/' }
    end

    class ActionMovieSerializer < GenreMovieSerializer
      link(:url) { |object| "/action-movie/#{object.id}" }
    end

    class HorrorMovieSerializer < GenreMovieSerializer
      link(:url) { |object| "/horror-movie/#{object.id}" }
    end

    class OptionalDownloadableMovieSerializer < MovieSerializer
      link(:download, if: proc { |_record, params| params && params[:signed_url] }) do |_movie, params|
        params[:signed_url]
      end
    end

    class OptionalDownloadableMovieWithLambdaSerializer < MovieSerializer
      link(:download, if: ->(record) { record.release_year >= 2000 }) do |movie|
        "/download/#{movie.id}"
      end
    end

    class MovieWithoutIdStructSerializer
      include FastJsonapi::ObjectSerializer
      attributes :name, :release_year
    end

    class CachingMovieSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      has_many :actors
      belongs_to :owner, record_type: :user
      belongs_to :movie_type

      cache_options store: ActiveSupport::Cache::MemoryStore.new, expires_in: 5.minutes
    end

    class CachingMovieWithHasManySerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
      has_many :actors, cached: true
      belongs_to :owner, record_type: :user
      belongs_to :movie_type

      cache_options store: ActiveSupport::Cache::MemoryStore.new, namespace: 'fast-jsonapi'
    end

    class ActorSerializer
      include FastJsonapi::ObjectSerializer
      set_type :actor
      attributes :name, :email
      belongs_to :agency
      has_many :awards
      belongs_to :agency
    end

    class AgencySerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      belongs_to :state
      has_many :actors
    end

    class AwardSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :title
      attribute :year, if: proc { |_record, params|
        if params[:include_award_year].present?
          params[:include_award_year]
        else
          false
        end
      }
      belongs_to :actor
    end

    class StateSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      has_many :agency
    end

    class AdvertisingCampaignSerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      belongs_to :movie
    end

    class MovieTypeSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie_type
      attributes :name
      has_many :movies
    end

    class MovieSerializerWithAttributeBlock
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
    end

    class MovieSerializerWithAttributeBlock
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name, :release_year
    end

    class AgencySerializer
      include FastJsonapi::ObjectSerializer
      attributes :id, :name
      has_many :actors
    end

    class SupplierSerializer
      include FastJsonapi::ObjectSerializer
      set_type :supplier
      has_one :account
    end

    class AccountSerializer
      include FastJsonapi::ObjectSerializer
      set_type :account
      belongs_to :supplier
    end

    class MovieOptionalRecordDataSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      attribute :release_year, if: proc { |record| record.release_year >= 2000 }
    end

    class MovieOptionalRecordDataWithLambdaSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      attribute :release_year, if: ->(record) { record.release_year >= 2000 }
    end

    class MovieOptionalParamsDataSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      attribute :director, if: proc { |_record, params| params[:admin] == true }
    end

    class MovieOptionalRelationshipSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      has_many :actors, if: proc { |record| record.actors.any? }
    end

    class MovieOptionalRelationshipWithLambdaSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      has_many :actors, if: ->(record) { record.actors.any? }
    end

    class MovieOptionalRelationshipWithParamsSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      belongs_to :owner, record_type: :user, if: proc { |_record, params| params[:admin] == true }
    end

    class MovieOptionalAttributeContentsWithParamsSerializer
      include FastJsonapi::ObjectSerializer
      set_type :movie
      attributes :name
      attribute :director do |_record, params|
        data = {}
        data[:first_name] = 'steven'
        data[:last_name] = 'spielberg' if params[:admin]
        data
      end
    end
  end

  # Namespaced MovieSerializer
  before(:context) do
    # namespaced model stub
    module AppName
      module V1
        class MovieSerializer
          include FastJsonapi::ObjectSerializer
          # to test if compute_serializer_name works
        end
      end
    end
  end

  # Movie and Actor struct
  before(:context) do
    MovieStruct = Struct.new(
      :id,
      :name,
      :release_year,
      :actor_ids,
      :actors,
      :owner_id,
      :owner,
      :movie_type_id,
      :advertising_campaign_id
    )

    ActorStruct = Struct.new(:id, :name, :email, :agency_id, :award_ids)
    MovieWithoutIdStruct = Struct.new(:name, :release_year)
    AgencyStruct = Struct.new(:id, :name, :actor_ids)
  end

  after(:context) do
    classes_to_remove = %i[
      ActionMovieSerializer
      GenreMovieSerializer
      HorrorMovieSerializer
      OptionalDownloadableMovieSerializer
      OptionalDownloadableMovieWithLambdaSerializer
      Movie
      MovieSerializer
      Actor
      ActorSerializer
      MovieType
      MovieTypeSerializer
      AppName::V1::MovieSerializer
      MovieStruct
      ActorStruct
      MovieWithoutIdStruct
      HyphenMovieSerializer
      MovieWithoutIdStructSerializer
      Agency
      AgencyStruct
      AgencySerializer
      AdvertisingCampaign
      AdvertisingCampaignSerializer
    ]
    classes_to_remove.each do |klass_name|
      Object.send(:remove_const, klass_name) if Object.constants.include?(klass_name)
    end
  end

  let(:movie_struct) do
    actors = []

    3.times.each do |id|
      actors << ActorStruct.new(id, id.to_s, id.to_s, id, [id])
    end

    m = MovieStruct.new
    m[:id] = 23
    m[:name] = 'struct movie'
    m[:release_year] = 1987
    m[:actor_ids] = [1, 2, 3]
    m[:owner_id] = 3
    m[:movie_type_id] = 2
    m[:actors] = actors
    m
  end

  let(:movie_struct_without_id) do
    MovieWithoutIdStruct.new('struct without id', 2018)
  end

  let(:movie) do
    m = Movie.new
    m.id = 232
    m.name = 'test movie'
    m.actor_ids = [1, 2, 3]
    m.owner_id = 3
    m.movie_type_id = 1
    m
  end

  let(:actor) do
    Actor.new.tap do |a|
      a.id = 234
      a.name = 'test actor'
      a.email = 'test@test.com'
      a.agency_id = 432
    end
  end

  let(:movie_type) do
    movie

    mt = MovieType.new
    mt.id = movie.movie_type_id
    mt.name = 'Foreign Thriller'
    mt.movie_ids = [movie.id]
    mt
  end

  let(:supplier) do
    s = Supplier.new
    s.id = 1
    s.account_id = 1
    s
  end

  def build_movies(count)
    count.times.map do |i|
      m = Movie.new
      m.id = i + 1
      m.name = 'test movie'
      m.actor_ids = [1, 2, 3]
      m.owner_id = 3
      m.movie_type_id = 1
      m
    end
  end
end
