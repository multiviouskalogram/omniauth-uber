require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Uber < OmniAuth::Strategies::OAuth2

      DEFAULT_SCOPE = 'profile'.freeze

      # TODO: Update this to API v1.2. !!!HOLD!!! All the required endpoints are not yet available in 1.2, particularly the partner endpoints.

      option :client_options,
        site: 'https://api.uber.com',
        authorize_url: 'https://login.uber.com/oauth/authorize',
        token_url: 'https://login.uber.com/oauth/token'

      uid { raw_info['uuid'] }

      info do
        {
          first_name: raw_info['first_name'],
          last_name: raw_info['last_name'],
          email: raw_info['email'],
          picture: raw_info['picture'],
          promo_code: raw_info['promo_code']
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def callback_url
        # NOTE: This method is originally defined in OmniAuth::Strategy, which OmniAuth::Strategies::OAuth2 includes/inherits from.
        # NOTE: When the callback_host option is not provided as an option, this will fallback to the orignal definition via super.
        # NOTE: By default, Uber Omniauth will try and send the callback back to requester. This is a problem when the link on our marketing site is the requester, but the API needs to be the receiver. This allows us to retarget.
        # NOTE: A callback_path should always be passed as an option, even if a callback_host is not.

        callback_host = options[:callback_host]

        if callback_host
          callback_host + script_name + callback_path + query_string
        else
          # NOTE: super logic: full_host + script_name + callback_path + query_string
          super
        end
      end

      def raw_info
        @raw_info ||= access_token.get('/v1/me').parsed || {}
      end

      def request_phase
        options[:authorize_params] = {
          client_id: options['client_id'],
          response_type: 'code',
          scopes: (options['scope'] || DEFAULT_SCOPE)
        }

        # NOTE: To see if the options path is being applied.
        # puts callback_path
        # => /api/v4/customers/auth/uber/callback
        # puts callback_url
        # => http://localhost:3001/api/v4/customers/auth/uber/callback

        # NOTE: To see the full request uri generated with params.
        # NOTE: This is the merger that happens by the super call below.
        # puts client.auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params)).inspect

        super
      end

    end # class Uber
  end # module Strategies
end # module OmniAuth
