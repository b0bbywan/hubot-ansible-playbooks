# Description:
#   A hubot script for launching ansible playbooks
#
# Commands:
#   hubot update <environment> [limit <hosts>] [only <tags>] [skip <tags>] [with <key>:<value>] - Execute the ansible playbook on the given environment
#
# Dependencies:
#   "node-ansible": "^0.5.5"
#
# Author:
#   Mathieu Réquillart

Ansible = require('node-ansible')
settings = require './ansible_settings'

module.exports = (robot) ->
  robot.respond /update (\w+((-|_)\w+)*)( limit (\w*))?( only (\w*(,\w*)*))?( skip (\w*(,\w*)*))?( with (\w*:.*(,\w*:.*)*))?/i, (msg) ->
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

    buffer = []
    handleTimeOut = null
    bufferInterval = 1000

    emptyBuffer = ->
      if buffer.length > 0
        msg.send buffer.join('\n')
          .replace(new RegExp(/ok: /g), ":check: ok: ")
          .replace(new RegExp(/failed: /g), ":failed: failed: ")
          .replace(new RegExp(/skipping: /g), ":skip: skipping: ")
          .replace(new RegExp(/changed: /g), ":changed: changed: ")
          .replace(new RegExp(/fatal: /g), ":fatal: fatal: ")
        buffer = []
        handleTimeOut = setTimeout(emptyBuffer, bufferInterval)
      else
        handleTimeOut = null
      return

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
    description = "updating: #{target}"
    if (limit?)
      playbook = playbook.limit(limit)
      description = description + " limiting to #{limit}"
    if (tags?)
      playbook = playbook.tags(tags)
      description = description + " only with #{tags}"
    if (skip_tags?)
      playbook = playbook.skipTags(skip_tags)
      description = description + " without #{skip_tags}"
    if (vars?)
      playbook = playbook.variables(varsJsonObj)
      description = description + " replacing #{vars}"

    msg.send description

    playbook.on 'stdout', (data) ->
      buffer.push data.toString()
      if handleTimeOut == null
        handleTimeOut = setTimeout(emptyBuffer, bufferInterval)
      return

    playbook.on 'stderr', (data) ->
      buffer.push data.toString()
      if handleTimeOut == null
        handleTimeOut = setTimeout(emptyBuffer, bufferInterval)
      return

    playbook.exec cwd: cwd
