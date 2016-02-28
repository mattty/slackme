require 'sinatra'
require 'groupme'
require 'rest-client'
require 'pry'

GROUPME_TOKEN = 'caxkys5KzGBr0gdKGBcQd0ncCCedwhpar4Y4pbOU'
SLACK_INCOMING_WEBHOOK = 'https://hooks.slack.com/services/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'
ROOM_MAPPINGS = {
  "groupme_to_slack" => {
    "20149784" => "#groupme-test",
    "2219445" => "#popo",
    "13521286" => "#boys-family-chat",
  },
  "slack_to_groupme" => {
    "groupme-test" => "20149784",
    "popo" => "2219445",
    "boys-family-chat" => "13521286",
  },
}
SLACK_TOKENS = {
  'groupme-test' => 'nT7lph6bvjVUxDXO2BPf6071',
  'popo' => 'k4tItvuK6hHUf6seCVee0cu7',
  'boys-family-chat' => 'XePvFL4Fhuf3KbsOUQluT1bF',
}
AUTHED_USERS = {
  'slack' => 'matt',
  'groupme' => 'Matt Boys',
} 

helpers do
  def groupme_client
    @groupme_client = GroupMe::Client.new token: GROUPME_TOKEN
  end
end

get '/' do
  200
end

get '/groups' do
  groups = groupme_client.groups

  # erb '/groups', 
  erb :groups, locals: {groups: groups}
end

post '/from_groupme' do
  message = request.env['rack.input'].read
  msg = JSON.parse(message)
  return if msg['name'] == AUTHED_USERS['groupme']
  fm = {
    channel: '#general',
    username: msg['name'],
    text: msg['text'],
    icon_url: msg['avatar_url'],
    channel: ROOM_MAPPINGS['groupme_to_slack'][msg['group_id']],
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

  RestClient.post SLACK_INCOMING_WEBHOOK, fm.to_json
end

post '/from_slack' do
  channel = params['channel_name']
  return 404 unless params['token'] == SLACK_TOKENS[channel]
  return unless params['user_name'] == AUTHED_USERS['slack']
  message = params['text']
  return unless message
  group_id = ROOM_MAPPINGS['slack_to_groupme'][channel]
  begin
    groupme_client.create_message group_id, message
    200
  rescue error => e
    e
  end
end

# example message from groupme:

# => {"attachments"=>[{"type"=>"image", "url"=>"https://i.groupme.com/636x640.jpeg.159b46bcaa084345aa5dd2d2ca5d55df"}],
#  "avatar_url"=>"https://i.groupme.com/2cfac150a834012fb3041231381d5c43",
#  "created_at"=>1456606598,
#  "group_id"=>"20149784",
#  "id"=>"145660659883159780",
#  "name"=>"Matt Boys",
#  "sender_id"=>"3008892",
#  "sender_type"=>"user",
#  "source_guid"=>"dde874ac3559b989b7f44d1586d4f37f",
#  "system"=>false,
#  "text"=>"",
#  "user_id"=>"3008892"}


# client.create_message test_group_id, "hello world!"

# client.create_bot 'test_bot', TEST_GROUP_ID, callback_url: "https://jrmkshagbs.localtunnel.me"

# example msg from slack
# => {"token"=>"nT7lph6bvjVUxDXO2BPf6071",
#  "team_id"=>"T0P62QWL9",
#  "team_domain"=>"mattty",
#  "service_id"=>"23400560336",
#  "channel_id"=>"C0PBPC90Q",
#  "channel_name"=>"groupme-test",
#  "timestamp"=>"1456610911.000010",
#  "user_id"=>"U0P61V8D6",
#  "user_name"=>"matt",
#  "text"=>"test123"}

