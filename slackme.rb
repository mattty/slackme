require 'sinatra'
require 'groupme'
require 'rest-client'

helpers do
  def groupme_client
    @groupme_client = GroupMe::Client.new token: ENV['GROUPME_TOKEN']
  end
end

get '/' do
  200
end

post '/from_groupme' do
  message = request.env['rack.input'].read
  msg = JSON.parse(message)
  return if msg['name'] == ENV['AUTHED_USERS']['groupme']
  fm = {
    channel: '#general',
    username: msg['name'],
    text: msg['text'],
    icon_url: msg['avatar_url'],
    channel: ENV['ROOM_MAPPINGS']['groupme_to_slack'][msg['group_id']],
    attachments: [],
  }

  msg['attachments'].each do |attachment|
    if attachment['type'] == 'image'
      a = {
        fallback: "Sent a pic",
        image_url: attachment['url'],
      }
      fm[:attachments].push(a)
    end
  end

  RestClient.post ENV['SLACK_INCOMING_WEBHOOK'], fm.to_json
end

post '/from_slack' do
  channel = params['channel_name']
  return 404 unless params['token'] == ENV['SLACK_TOKENS'][channel]
  return unless params['user_name'] == ENV['AUTHED_USERS']['slack']
  message = params['text']
  return unless message
  group_id = ENV['ROOM_MAPPINGS']['slack_to_groupme'][channel]
  groupme_client.create_message group_id, message
end
