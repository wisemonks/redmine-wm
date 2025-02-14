module Mattermost
  class MattermostSDK
    include HTTParty
    base_uri 'https://mattermost.wisemonks.com/api/v4'

    def initialize(bearer_token)
      @headers = {
        'Authorization' => "Bearer #{bearer_token}",
        'Content-Type' => 'application/json'
      }
    end

    def create_post(channel_id, message, root_id = nil)
      body = {
        channel_id: channel_id,
        message: message
      }
      body[:root_id] = root_id if root_id

      self.class.post(
        '/posts',
        headers: @headers,
        body: body.to_json
      )
    end

    def get_post(post_id)
      self.class.get(
        "/posts/#{post_id}",
        headers: @headers
      )
    end

    def get_reactions(post_id)
      response = get_post(post_id)
      response.dig('metadata', 'reactions') || []
    end

    def format_issue_message(issue)
      issue_url = "[##{issue.id} [#{issue.tracker.name}] #{issue.subject}](https://redmine.wisemonks.com/issues/#{issue.id})"
      message = "### #{issue.project.name}\n\n"
      message += "A new issue has been created: #{issue_url}\n"
      message += "Estimate: #{issue.estimated_hours}\n\n"
      message += issue.description.to_s
      message
    end
  end
end