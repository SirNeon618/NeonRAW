require_relative '../../objects/wikipage'

module NeonRAW
  module Clients
    class Base
      # Utilities for the base client.
      module Utilities
        # Search for subreddits.
        # @!method find_subreddits(query)
        # @param query [String] The name to search for (50 characters maximum).
        # @return [Array<String>] Returns the list of subreddits.
        def find_subreddits(query)
          params = { query: query }
          data = request_data('/api/subreddits_by_topic', :get, params)
          data.map { |subreddit| subreddit[:name] }
        end

        # Fetches subreddits.
        # @!method get_popular(params = { limit: 25 })
        # @!method get_new(params = { limit: 25 })
        # @!method get_gold(params = { limit: 25 })
        # @!method get_defaults(params = { limit: 25 })
        # @param params [Hash] The parameters.
        # @option params :after [String] Fullname of the next data block.
        # @option params :before [String] Fullname of the previous data block.
        # @option params :count [Integer] The number of items already in the
        #   listing.
        # @option params :limit [1..1000] The number of listing items to fetch.
        # @option params :show [String] Literally the string 'all'.
        # @return [NeonRAW::Objects::Listing] Returns a listing of all the
        #   subreddits.
        %w(popular new gold defaults).each do |type|
          define_method :"get_#{type}" do |params = { limit: 25 }|
            type.chop! if type == 'defaults'
            build_listing("/subreddits/#{type}", params)
          end
        end

        # Fetches a wiki page.
        # @!method get_wikipage(page)
        # @param page [String] The name of the page.
        # @return [NeonRAW::Objects::WikiPage] Returns the wiki page object.
        def get_wikipage(page)
          params = { page: page }
          path = "/wiki/#{page}.json"
          data = request_data(path, :get, params)
          data[:data][:name] = page
          Objects::WikiPage.new(@client, data[:data])
        end

        # Fetches a list of wiki pages from Reddit.
        # @!method wikipages
        # @return [Array<String>] Returns a list of wiki pages.
        def wikipages
          request_data('/wiki/pages.json', :get)[:data]
        end
      end
    end
  end
end
