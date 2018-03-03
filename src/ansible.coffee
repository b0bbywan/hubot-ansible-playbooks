# Description:
#   A hubot script to launch ansible playbooks
#
# Commands:
#   hubot update <environment> [limit <hosts>] [only <tags>] [skip <tags>] [with <key>:<value>] - Execute the ansible playbook on the given environment
#
# Dependencies:
#   "node-ansible": "^0.5.5"
#
# Author:
#   Mathieu Réquillart

Ansible = require 'node-ansible'
settings = require process.env.HUBOT_ANSIBLE_SETTINGS

String::startsWith ?= (s) -> @slice(0, s.length) == s

buffer = []
aTaskResult = []

handleBufferTimeOut = null
bufferInterval = 1000

handleTaskTimeout= null
bufferTaskInterval = 5000

recapMode = false
failedMode = false

taskPattern = //
playPattern = /PLAY (\[([a-zA-Z0-9-_\.]+)\])? \*+/
playRecapPattern = /PLAY RECAP \*+/
handlerPattern = /RUNNING HANDLER \[([a-zA-Z0-9-_]+)( : (([a-zA-Z0-9-/_]+ ?)*))?\] \*+/
noMoreHostLeftPattern = /NO MORE HOSTS LEFT \*+/
deprecationWarningPattern = /\[DEPRECATION WARNING\]/
emptyStringPattern = /^\s*$/

base_report = {
  "attachments": [
    {
      "fallback": "Deployment report",
      "author_name": "Ansible Report",
      "author_icon": "https://avatars3.githubusercontent.com/u/1507452?v=2&s=32",
      "title": "PLAY RECAP",
      "fields": [
      ],
    }
  ],
  "username": process.env.HUBOT_SLACK_BOTNAME,
  "as_user": true,
}


module.exports = (robot) ->
  robot.respond /update (\w+((-|_)\w+)*)( limit (\w*))?( only (\w*(,\w*)*))?( skip (\w*(,\w*)*))?( with (\w*:.*(,\w*:.*)*))?/i, (msg) ->

    sendRecap = ->
      msg.send base_report
      recapMode = false

    emptyBuffer = ->
      if buffer.length > 0
        msg.send buffer.join('\n')
          .replace(new RegExp(/ok: /g), ":heavy_check_mark: ok: ")
          .replace(new RegExp(/failed: /g), ":x: failed: ")
          .replace(new RegExp(/skipping: /g), ":white_check_mark: skipping: ")
          .replace(new RegExp(/changed: /g), ":heavy_plus_sign: changed: ")
          .replace(new RegExp(/fatal: /g), ":sos: fatal: ")
          .replace(new RegExp(/\[DEPRECATION WARNING\]: /g), ":exclamation: warning: ")
        buffer = []
        handleBufferTimeOut = setTimeout(emptyBuffer, bufferInterval)
      else
        handleBufferTimeOut = null
      return

    pushChangingTask = ->
      robot.logger.debug "sending #{aTaskResult} early"
      buffer.push aTaskResult...
      aTaskResult = ['']
      handleTaskTimeout = null
      if handleBufferTimeOut == null
        handleBufferTimeOut = setTimeout(emptyBuffer, bufferInterval)

    onTaskMatch = (message) ->
      robot.logger.debug("task match")
      if aTaskResult.length > 1
        robot.logger.debug 'match'
        buffer.push aTaskResult...
        if handleBufferTimeOut == null
          handleBufferTimeOut = setTimeout(emptyBuffer, bufferInterval)
      if message.match taskPattern
        handleTaskTimeout = setTimeout(pushChangingTask, bufferTaskInterval)
      aTaskResult = []
      aTaskResult.push message


    filterBuffer = (message) ->
      robot.logger.info message
      if handleTaskTimeout != null
        clearTimeout(handleTaskTimeout)
        handleTaskTimeout = null
      if message.match playPattern
        robot.logger.debug "play pattern detected #{message}"
        match = message.match playPattern
        if (limit?) && match[2] == limit
          robot.logger.debug "limit: #{limit}, host: #{match[2]}, #{match[1]}"
          buffer.push message
      else if message.startsWith "TASK"
        robot.logger.debug "task pattern detected #{message}"
        onTaskMatch message
      else if message.startsWith "RUNNING HANDLER"
        robot.logger.debug "handler pattern detected #{message}"
        onTaskMatch message
      else if (message.match noMoreHostLeftPattern)
        onTaskMatch message
        failedMode = true
      else if (message.match playRecapPattern)
        onTaskMatch message
        robot.logger.debug "recap mode activated"
        failedMode = false
        recapMode = true
        base_report.attachments[0].fields = []
        setTimeout(sendRecap, 10000)
      else
        if (message.startsWith 'ok') or (message.startsWith 'skipping')
          if (process.env.HUBOT_ANSIBLE_VERBOSE?)
            aTaskResult.push message
          else
            robot.logger.debug "skipped message : #{message}"
        else if (message.startsWith 'failed') or (message.startsWith 'fatal') or (message.startsWith 'changed') or (message.match deprecationWarningPattern)
          aTaskResult.push message
        else if failedMode
          buffer.push message
        else if recapMode
          splittedMessage = message.split(':')
          if splittedMessage.length > 1
            host = splittedMessage[0].trim()
            result = splittedMessage[1].trim()
            field = {"title": host, "value": result, short: false}
            robot.logger.debug field
            base_report.attachments[0].fields.push field
        else
          robot.logger.warning "warn: #{message} did not match"
          buffer.push message


    target = msg.match[1]
    if !settings.hasOwnProperty(target)
      msg.send "Unknown environment"
      return
    if msg.message.user.id not in settings['admin_users'] and msg.message.user.id not in settings[target]['authorized_users']
      msg.send "Sorry bro', you're not allowed to do this"
      return
    invfile = "inventory/" + settings[target]['inventory']
    playbook = settings[target]['playbook']
    cwd = settings['path']

    robot.emit "ansible_update", {
      msg: msg
    }

    if msg.match[4]
      limit = msg.match[5].trim()
    if msg.match[6]
      tags = msg.match[7].trim().split ","
    if msg.match[9]
      skip_tags = msg.match[10].trim().split ","
    if msg.match[12]
      vars = msg.match[13].trim().split ","
      varsJsonString = {}
      i = 0
      while i < vars.length
        eltArray = vars[i].trim().split(':')
        varsJsonString[eltArray[0]] = eltArray[1]
        i++
      varsJsonObj = JSON.parse JSON.stringify(varsJsonString)

    playbook = (new (Ansible.Playbook)).inventory(invfile).playbook(playbook)
    description = "updating: *#{target}*"
    if (limit?)
      playbook = playbook.limit(limit)
      description = description + " limiting to *#{limit}*"
    if (tags?)
      playbook = playbook.tags(tags)
      description = description + " only with *#{tags}*"
    if (skip_tags?)
      playbook = playbook.skipTags(skip_tags)
      description = description + " without *#{skip_tags}*"
    if (vars?)
      playbook = playbook.variables(varsJsonObj)
      description = description + " replacing *#{vars}*"

    msg.send description

    playbook.on 'stdout', (data) ->
      results = data.toString().split('\n')
      results.forEach (r) ->
        if !r.match emptyStringPattern
          filterBuffer r, limit
        return
      if handleBufferTimeOut == null
        handleBufferTimeOut = setTimeout(emptyBuffer, bufferInterval)
      return

    playbook.on 'stderr', (data) ->
      results = data.toString().split('\n')
      results.forEach (r) ->
        filterBuffer r
        return
      if handleBufferTimeOut == null
        handleBufferTimeOut = setTimeout(emptyBuffer, bufferInterval)
      return

    playbook.exec cwd: cwd
