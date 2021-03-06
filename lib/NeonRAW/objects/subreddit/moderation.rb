require_relative '../thing'
require_relative '../modloguser'
require_relative '../listing'

module NeonRAW
  module Objects
    class Subreddit < Thing
      # Methods for moderators.
      module Moderation
        # @!group Listing
        # Fetches the modlog for the subreddit.
        # @!method modlog(params = { limit: 25 })
        # @param params [Hash] The parameters.
        # @option params :after [String] Fullname of the next data block.
        # @option params :before [String] Fullname of the previous data block.
        # @option params :count [Integer] The number of items already in the
        #   listing.
        # @option params :limit [1..500] The number of listing items to fetch.
        # @option params :mod [String] The moderator to filter actions by. Also
        #   'a' can be given to filter by admin actions.
        # @option params :show [String] Literally the string 'all'.
        # @option params :type [String] The type of mod action to filter by
        #   [banuser, unbanuser, removelink, approvelink, removecomment,
        #   approvecomment, addmoderator, invitemoderator, uninvitemoderator,
        #   acceptmoderatorinvite, removemoderator, addcontributor,
        #   removecontributor, editsettings, editflair, distinguish, marknsfw,
        #   wikibanned, wikicontributor, wikiunbanned, wikipagelisted,
        #   removewikicontributor, wikirevise, wikipermlevel, ignorereports,
        #   unignorereports, setpermissions, setsuggestedsort, sticky, unsticky,
        #   setcontestmode, unsetcontestmode, lock, unlock, muteuser,
        #   unmuteuser, createrule, editrule, deleterule]
        # @return [NeonRAW::Objects::Listing] Returns a listing of the modlog
        #   actions.
        def modlog(params = { limit: 25 })
          path = "/r/#{display_name}/about/log"
          @client.send(:build_listing, path, params)
        end

        # Fetches the subreddit's modmail.
        # @!method modmail(params = { limit: 25 })
        # @param params [Hash] The parameters.
        # @option params :after [String] Fullname of the next data block.
        # @option params :before [String] Fullname of the previous data block.
        # @option params :count [Integer] The number of things already in the
        #   listing.
        # @option params :limit [1..1000] The number of listing items to fetch.
        # @option params :only [Symbol] Only fetch either [links, comments].
        # @option params :show [String] Literally the string 'all'.
        # @return [NeonRAW::Objects::Listing] Returns a listing with all the
        #   things.
        def modmail(params = { limit: 25 })
          path = "/r/#{display_name}/about/message/inbox"
          @client.send(:build_listing, path, params)
        end

        # Fetches things for review by moderators.
        # @!method reported(params = { limit: 25 })
        # @!method spam(params = { limit: 25 })
        # @!method modqueue(params = { limit: 25 })
        # @!method unmoderated(params = { limit: 25 })
        # @!method edited(params = { limit: 25 })
        # @param params [Hash] The parameters.
        # @option params :after [String] Fullname of the next data block.
        # @option params :before [String] Fullname of the previous data block.
        # @option params :count [Integer] The number of things already in the
        #   listing.
        # @option params :limit [1..1000] The number of listing items to fetch.
        # @option params :only [Symbol] Only fetch either [links, comments].
        # @option params :show [String] Literally the string 'all'.
        # @return [NeonRAW::Objects::Listing] Returns a listing with all the
        #   things.
        %w[reported spam modqueue unmoderated edited].each do |type|
          define_method :"#{type}" do |params = { limit: 25 }|
            type = 'reports' if type == 'reported'
            path = "/r/#{display_name}/about/#{type}"
            @client.send(:build_listing, path, params)
          end
        end

        # Fetches users with altered privileges.
        # @!method banned(params = { limit: 25 })
        # @!method muted(params = { limit: 25 })
        # @!method wikibanned(params = { limit: 25 })
        # @!method contributors(params = { limit: 25 })
        # @!method wikicontributors(params = { limit: 25 })
        # @!method moderators(params = { limit: 25 })
        # @param params [Hash] The parameters.
        # @option params :after [String] Fullname of the next data block.
        # @option params :before [String] Fullname of the previous data block.
        # @option params :count [Integer] Number of items already in the
        #   listing.
        # @option params :limit [1..1000] The number of listing items to fetch.
        # @option params :show [String] Literally the string 'all'.
        # @option params :user [String] The name of the user to fetch.
        # @return [NeonRAW::Objects::Listing] Returns a listing of the users.
        %w[banned muted wikibanned
           contributors wikicontributors moderators].each do |type|
             define_method :"#{type}" do |params = { limit: 25 }|
               data_arr = []
               path = "/r/#{display_name}/about/#{type}"
               until data_arr.length == params[:limit]
                 data = @client.request_data(path, :get, params)
                 params[:after] = data[:data][:after]
                 params[:before] = data[:data][:before]
                 data[:data][:children].each do |item|
                   data_arr << ModLogUser.new(@client, item)
                   break if data_arr.length == params[:limit]
                 end
                 break if params[:after].nil?
               end
               listing = Listing.new(params[:after], params[:before])
               data_arr.each { |user| listing << user }
               listing
             end
           end
        # @!endgroup

        # Accept a pending mod invite to the subreddit.
        # @!method accept_mod_invite!
        def accept_mod_invite!
          params = { api_type: 'json' }
          path = "/r/#{display_name}/api/accept_moderator_invite"
          @client.request_data(path, :post, params)
          refresh!
        end

        # Ditch your privileged status in the subreddit.
        # @!method leave_contributor!
        # @!method leave_moderator!
        %w[contributor moderator].each do |type|
          define_method :"leave_#{type}!" do
            params = { id: name }
            @client.request_data("/api/leave#{type}", :post, params)
            refresh!
          end
        end

        # Upload a subreddit image.
        # @!method upload_image!(file_path, file_type, image_name, upload_type)
        # @param file_path [String] The path to the file (500 KiB maximum).
        # @param file_type [String] The file extension [png, jpg].
        # @param image_name [String] The name of the image.
        # @param upload_type [String] The type of upload [img, header, icon,
        #   banner].
        def upload_image!(file_path, file_type, image_name, upload_type)
          params = { img_type: file_type, name: image_name,
                     upload_type: upload_type }
          path = "/r/#{display_name}/api/upload_sr_img"
          file = File.open(file_path, 'r')
          @client.request_data(path, :post, params, file: file)
          refresh!
        end

        # Remove a subreddit image.
        # @!method remove_banner!
        # @!method remove_header!
        # @!method remove_icon!
        %w[banner header icon].each do |type|
          define_method :"remove_#{type}!" do
            params = { api_type: 'json' }
            path = "/r/#{display_name}/api/delete_sr_#{type}"
            @client.request_data(path, :post, params)
            refresh!
          end
        end

        # Remove a subreddit image.
        # @!method remove_image!(image)
        # @param image [String] The name of the image.
        def remove_image!(image)
          params = { api_type: 'json', img_name: image }
          path = "/r/#{display_name}/api/delete_sr_img"
          @client.request_data(path, :post, params)
          refresh!
        end

        # Edit the subreddit's stylesheet.
        # @!method edit_stylesheet(data, opts = {})
        # @param data [String] The CSS for the stylesheet.
        # @param opts [Hash] Optional parameters.
        # @option opts :reason [String] The reason for the edit (256 characters
        #   maximum).
        def edit_stylesheet(data, opts = {})
          params = { api_type: 'json', op: 'save',
                     reason: opts[:reason], stylesheet_contents: data }
          path = "/r/#{display_name}/api/subreddit_stylesheet"
          @client.request_data(path, :post, params)
        end

        # Fetches the settings for the subreddit.
        # @!method settings
        # @return [Hash] Returns the subreddit's settings.
        def settings
          path = "/r/#{display_name}/about/edit"
          @client.request_data(path, :get)[:data]
        end
      end
    end
  end
end
