module NeonRAW
  module Objects
    class Thing
      # Methods for moderators.
      # @!attribute [r] mod_reports
      #   @return [Array<String>, nil] Returns the mod reports or nil if there
      #     are none.
      # @!attribute [r] user_reports
      #   @return [Array<String>, nil] Returns the user reports or nil if there
      #     are none.
      module Moderateable
        # Approve a comment or submission.
        # @!method approve!
        def approve!
          params = {}
          params[:id] = name
          @client.request_data('/api/approve', :post, params)
          refresh!
        end

        # Checks whether or not the thing was distinguished by a privileged
        # user.
        # @!method distinguished?
        # @return [Boolean] Returns whether or not the comment was
        #   distinguished.
        def distinguished?
          if @distinguished.nil?
            false
          else
            true
          end
        end

        # Distinguish a submission/comment.
        # @!method distinguish(type)
        # @param type [String] The type of distinguish you want to do [yes, no,
        #   admin, special].
        # @!group Moderators
        def distinguish(type)
          params = {}
          params[:api_type] = 'json'
          params[:how] = type
          params[:id] = name
          @client.request_data('/api/distinguish', :post, params)
          refresh!
        end

        # Checks who distinguished the thing.
        # @!method distinguished_by
        # @return [String, nil] Returns who distinguished the comment or nil if
        #   the comment isn't distinguished [moderator, admin, special].
        def distinguished_by
          @distinguished
        end

        # Checks whether or not the thing is stickied.
        # @!method stickied?
        # @return [Boolean] Returns whether or not the thing is stickied.
        def stickied?
          @stickied
        end

        # Report a thing to the subreddit's moderators or admins if the thing
        # is a private message.
        # @!method report(reason)
        # @param reason [String] The reason for the report (100 characters
        #   maximum).
        def report(reason)
          params = {}
          params[:api_type] = 'json'
          params[:reason] = reason
          params[:thing_id] = name
          @client.request_data('/api/report', :post, params)
        end

        # Set whether to ignore reports on the thing or not.
        # @!method ignore_reports!
        # @!method unignore_reports!
        %w(ignore unignore).each do |type|
          define_method :"#{type}_reports!" do
            params = {}
            params[:id] = name
            @client.request_data("/api/#{type}_reports", :post, params)
          end
        end

        # Remove a comment/link/modmail message.
        # @!method remove!
        def remove!
          params = {}
          params[:id] = name
          params[:spam] = false
          @client.request_data('/api/remove', :post, params)
          refresh!
        end

        # Spamfilter a comment/link/modmail message.
        # @!method spam!
        def spam!
          params = {}
          params[:id] = name
          params[:spam] = true
          @client.request_data('/api/remove', :post, params)
          refresh!
        end
      end
    end
  end
end
