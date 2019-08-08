module Gentle
  class EngagementNoteActivity < Gentle::Base
    def initialize(touch)
      super(touch)
    end

    def create data
      response = HTTParty.post( Gentle_engagements_url, 
                                body: data.to_json, 
                                :headers => { 
                                  'Content-Type' => 'application/json', 
                                  'Authorization' => sprintf('Bearer %s', @provider_account.access_token)
                                })
    end

    def Gentle_engagements_url
      Gentle_API_BASE_URL + '/engagements/v1/engagements'
    end
  end
end
