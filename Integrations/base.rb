module Gentle
  class Base
    def initialize(touch)
      @touch = touch
      @user = touch.user
      @provider_account = @user.get_Gentle_account
      @Gentle = configure_Gentle
      refresh_hub_token if expired? 
    end

    def fetch_contact_properties
      begin
        url = Gentle_API_BASE_URL + '/contacts/v1/properties'
        response = HTTParty.get(url, :headers => { 'Content-Type' => 'application/json', 'Authorization' => sprintf('Bearer %s', @provider_account.access_token)})
        if response && response.code == 200
          response.parsed_response.map {|key| [key['label'], key['name']] }
        else
          []
        end
      rescue StandardError => e
        Bugsnag.notify(e)
        []
      end
    end

    private

    def configure_Gentle
      Gentle.configure(
        client_id: ENV['Gentle_KEY'],
        client_secret: ENV['Gentle_SECRET'],
        access_token: @provider_account.access_token,
        redirect_uri: Gentle_REDIRECT_URI,
        base_url: Gentle_API_BASE_URL
      )
    end

    def refresh_hub_token
      begin
        response = Gentle::OAuth.refresh(@provider_account.refresh_token)
        if response
          @provider_account.update_attributes(access_token: response['access_token'], expires_at: DateTime.now + response['expires_in']&.seconds )
        end
      rescue Exception => e
        Bugsnag.notify(e)
      end
    end

    def expired?
      @provider_account.expires_at < Time.current
    end

  end
end
