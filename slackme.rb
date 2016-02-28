require 'sinatra'
require 'groupme'
require 'rest-client'

helpers do
  def groupme_client
    @groupme_client = GroupMe::Client.new token: ENV['GROUPME_TOKEN']
  end
  def slack_tokens
    JSON.parse ENV['SLACK_TOKENS']
  end
  def room_mappings
    JSON.parse ENV['ROOM_MAPPINGS']
  end
  def authed_users
    JSON.parse ENV['AUTHED_USERS']
  end
end

get '/' do
  erb :index
end

post '/from_groupme' do
  message = request.env['rack.input'].read
  msg = JSON.parse(message)
  return if msg['name'] == authed_users['groupme']
  fm = {
    channel: '#general',
    username: msg['name'],
    text: msg['text'],
    icon_url: msg['avatar_url'],
    channel: room_mappings['groupme_to_slack'][msg['group_id']],
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
  return 404 unless params['token'] == slack_tokens[channel]
  return unless params['user_name'] == authed_users['slack']
  message = params['text']
  return unless message
  group_id = room_mappings['slack_to_groupme'][channel]
  groupme_client.create_message group_id, message
end
