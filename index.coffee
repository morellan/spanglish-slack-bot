Slack = require 'slack-client'
Teacher = require 'teacher'

token = 'xoxb-TOKEN' # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true
autoMark = true

slack = new Slack(token, autoReconnect, autoMark)

slack.on 'open', ->
  channels = []
  groups = []
  unreads = slack.getUnreadCount()

  # Get all the channels that bot is a member of
  channels = ("##{channel.name}" for id, channel of slack.channels when channel.is_member)

  # Get all groups that are open and not archived
  groups = (group.name for id, group of slack.groups when group.is_open and not group.is_archived)

  console.log "Welcome to Slack. You are @#{slack.self.name} of #{slack.team.name}"
  console.log 'You are in: ' + channels.join(', ')
  console.log 'As well as: ' + groups.join(', ')

  messages = if unreads is 1 then 'message' else 'messages'

  console.log "You have #{unreads} unread #{messages}"


slack.on 'message', (message) ->
  {type, ts, text} = message

  if not text? or text.indexOf("#check") < 0
    return

  text = text.replace '#check', ''

  channel = slack.getChannelGroupOrDMByID(message.channel)
  user = slack.getUserByID(message.user)

  channelName = if channel?.is_channel then '#' else ''
  channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

  userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

  response = "#{userName}, did you mean? "

  console.log """
    Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
  """

  # Respond to messages with the reverse of the text received.
  if type is 'message' and text? and channel?
    Teacher.check(text, (err, data) ->
      i = 0
      if data
        data.forEach (word) ->
          if  word.suggestions
            if word.suggestions.option instanceof Array
              correct = word.suggestions.option[0]
            else
              correct = word.suggestions.option

            text = text.replace word.string, correct

          if ++i == data.length
            channel.send "#{response} _#{text}_"
      else
        channel.send "*Exito!*"
    )

    console.log """
      @#{slack.self.name} responded with "#{response}"
    """
  else
    #this one should probably be impossible, since we're in slack.on 'message'
    typeError = if type isnt 'message' then "unexpected type #{type}." else null
    #Can happen on delete/edit/a few other events
    textError = if not text? then 'text was undefined.' else null
    #In theory some events could happen with no channel
    channelError = if not channel? then 'channel was undefined.' else null

    #Space delimited string of my errors
    errors = [typeError, textError, channelError].filter((element) -> element isnt null).join ' '

    console.log """
      @#{slack.self.name} could not respond. #{errors}
    """


slack.on 'error', (error) ->
  console.error "Error: #{error}"


slack.login()
