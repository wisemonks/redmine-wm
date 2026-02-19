module Mattermost
  class Base
    MATTERMOST_CHANNELS = {
      'valandiniai': '8yhkbwaxkt8ibfd6w4pd7ao6dr', # Valandiniai channel
      'performance': 'soibe9qnefn53y4yu7tu8zg9ce', # Performance channel
      'digest': 'z4nsrwfuujbaxned3t6hdczzhe', # AI digest channel
      'general': 'h3ze8pzw8tbwjyajk99d5feboc', # general channel
      'arturas': '8bobf9fiqbryfrkr6ciz3rm5ww', # Artūras
      'rytis': '4qa8z84metdo5gozjwbjr5geho', # Rytis
      'rokasabrutis': 'dcm5ywcw5jbkmxece4dnngex1r', # Rokas
      'raminta': 'store77e87g7zjuxi3ieg31roy', # Raminta
      'monika': 'pabetp7expfrdniyy66a654c1e', # Monika
      # 'agnetap': 'jxddbgtw6tntfcoah84uiap5ne', # Agneta
      'edvinas': 'mfh6rnigmiy7zrptoeioytfc8c', # Edvinas
      'adomas': 'bh8ojm7jmffomxrm84gbphruah', # Adomas
      'vilimaite': 'hofdhsfd9jnzxfwze9c5i1d11w' # Viktorija
    }

    def initialize
      @mattermost_url = 'https://mattermost.wisemonks.com/api/v4/posts'
      @headers = {
        'Authorization' => 'Bearer ' + Rails.application.credentials[:mattermost][:bearer]
      }  
    end

    def post_message(channel_id, message)
      body = { 'channel_id' => MATTERMOST_CHANNELS[channel_id] }
      body['message'] = message
      response = HTTParty.post(@mattermost_url, :headers => @headers, :body => body.to_json)
    end
  end
end