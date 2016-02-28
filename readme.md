# SlackMe

SlackMe stitches together Slack and GroupeMe, allowing you to use Slack as a client for GroupMe conversations (and vice versa). I have a Slack team set up with one channel for each GroupMe group I want to access via Slack. Then I have one GroupMe bot per group I want to access. This bot posts new messages in its group to the correct Slack channel (with the GroupMe user's name and photo attached!). My replies in Slack are routed to the appropriate GroupMe group by the appropriate bot (the messages show up as coming from me in GroupMe).

## Instructions

Set up one Slack channel and GroupMe bot for each group you want to access. Configure incoming & outgoing Slack webhooks for each channel. Run the Sinatra app with the environment variables below populated.

## Environment Variables

* GROUPME_TOKEN - a secret token for your GroupMe bot
* SLACK_INCOMING_WEBHOOK - a url to post messages to for Slack
* SLACK_TOKENS - one token for each channel you're using. This should be JSON encoded to a string, with the channel names as keys and the tokens as values. These tokens are used to verify that the incoming message is from Slack.
* ROOM_MAPPINGS - a mapping of GroupMe groups to Slack channels. This should be a nested hash (JSON encoded as a string) with the following keys:
 * "groupme_to_slack"
 * "slack_to_groupme"
* AUTHED_USERS - a hash (JSON encoded as a string) of users auth'd to send and receive messages. This has the practical effect of preventing messaging loops!