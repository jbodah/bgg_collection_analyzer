require 'bgg_collection_analyzer/version'
require 'bgg_api'

module BggCollectionAnalyzer
  module Math
    def self.average(enum)
      enum.reduce(:+) / enum.count
    end
  end

  def self.collection(username, full: true)
    res = BggApi.collection username, stats: 1

    if full
      res.each_slice(20).flat_map do |collection_game_slice|
        full_games = find_games collection_game_slice.map(&:id)
        collection_game_slice.each do |collection_game|
          collection_game.game = full_games.delete_at(0)
        end
      end
    else
      res
    end
  end

  def self.find_games(game_ids)
    Bgg::Game.find_batch_by_ids game_ids, stats: 1
  end

  [
    %i(mechanic mechanics),
    %i(category categories),
    %i(length lengths)
  ].each do |singular, plural|
    eval <<-EOF
      def self.by_#{singular}(collection)
        collection.reduce({}) do |memo, game|
          if game.respond_to?(:#{plural})
            game.#{plural}.each do |#{singular}|
              memo[#{singular}] ||= []
              memo[#{singular}] << game
            end
          else
            memo[game.#{singular}] ||= []
            memo[game.#{singular}] << game
          end
          memo
        end
      end

      def self.#{plural}_by_user_rating(collection)
        rated = collection.select(&:rated?)
        by_#{singular}(rated).reduce([]) do |memo, (#{singular}, games)|
          rating = Math.average games.map(&:user_rating)
          memo << [rating.round(2), #{singular}]
        end.sort.reverse
      end

      def self.owned_by_#{singular}(collection)
        by_#{singular}(collection).reduce({}) do |memo, (#{singular}, games)|
          games.select!(&:owned?)
          next memo if games.none?
          memo[#{singular}] = games
          memo
        end
      end

      def self.rated_by_#{singular}(collection)
        by_#{singular}(collection).reduce({}) do |memo, (#{singular}, games)|
          games.select!(&:rated?)
          next memo if games.none?
          memo[#{singular}] = games
          memo
        end
      end
    EOF
  end

  def self.preferred_length_by_weight(collection)
    %i(light medium heavy).reduce({}) do |memo, weight|
      games = collection.rated.send(weight)
      memo[weight] = BggCollectionAnalyzer.lengths_by_user_rating(games)[0][1]
      memo
    end
  end

  %i(categories mechanics).each do |sym|
    eval <<-EOF
      def self.#{sym}
        @#{sym} ||= YAML.load_file('#{sym}.yml').map(&:downcase).map { |w| w.gsub(/\\W+/, '_') }
      end
    EOF

    send(sym).each do |term|
      eval <<-EOF
        def self.favorite_#{term}_games(collection)
          collection.owned.rated.select { |g| g.categories.include? "#{term}" }.sort_by(&:user_rating).reverse
        end
      EOF
    end
  end

  %i(
    very_light light medium heavy very_heavy
    very_short short average long very_long
  ).each do |term|
    eval <<-EOF
      def self.favorite_#{term}_games(collection)
        collection.owned.rated.#{term}.sort_by(&:user_rating).reverse
      end
    EOF
  end

  def self.lack_combined_rating(collection)
    collection.owned.reject(&:lauren_rated?).reject(&:expansion?).reject(&:best_with_one?)
  end

  def self.purge_list(collection)
    collection.owned.lauren_rated.sort_by { |g| g.lauren_rating + g.josh_rating }.map { |g| [g.lauren_rating + g.josh_rating, g] }
  end

  %i(mechanics categories).each do |type|
    eval <<-EOF
      def self.score_#{type}(collection, rating: :user_rating)
        collection.rated.reduce({}) do |memo, game|
          game.#{type}.each do |m|
            memo[m] ||= { count: 0, total: 0, games: [] }
            memo[m][:count] += 1
            memo[m][:total] += game.send(rating)
            memo[m][:games] << game
          end
          memo
        end.map do |k, h|
          score = (h[:total] / h[:count] * 10).round(2)
          [score, k, h]
        end.sort_by(&:first).reverse
      end
    EOF
  end

  class CollectionQueryer
    include Enumerable

    def initialize(collection)
      @collection = collection
    end

    def each
      @collection.each(&Proc.new)
    end

    def method_missing(sym, *args, &block)
      return @collection.public_send(sym, *args, &block) if @collection.respond_to?(sym)
      sym = "#{sym}?".to_sym
      CollectionQueryer.new(@collection.select(&sym))
    end
  end
end

def collection
  @collection ||=
    BggCollectionAnalyzer::CollectionQueryer.new(
      BggCollectionAnalyzer.collection 'hiimjosh'
    )
end
