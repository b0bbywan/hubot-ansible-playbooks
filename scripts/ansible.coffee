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

marvin_quotes = [
  "Life! Don't talk to me about life",
  "Life's bad enough as it is without wanting to invent any more of it",
  "Funny, how just when you think life can't possibly get any worse it suddenly does",
  "I could calculate your chance of survival, but you won't like it",
  "I'd give you advice, but you wouldn't listen. No one ever does",
  "I've seen it. It's rubbish",
  "I think you ought to know I'm feeling very depressed",
  "Not that anyone cares what I say, but the Restaurant is on the other end of the universe",
  "Here I am, brain the size of a planet and they ask me to take you down to the bridge. Call that job satisfaction?",
  "Do you want me to sit in a corner and rust, or just fall apart where I’m standing?",
  "It’s the people you meet in this job that really get you down",
  "Incredible… it’s even worse than I thought it would be",
  "Don’t pretend you want to talk to me, I know you hate me",
  "The best conversation I had was over forty million years ago…. And that was with a coffee machine",
  "Well I wish you’d just tell me rather than try to engage my enthusiasm",
  "It gives me a headache just trying to think down to your level",
  "I won’t enjoy it",
  "Sounds awful",
  ]

settings = {
  'path': '/home/ansible/metod-deploy/',
  'prod': {
     'inventory': 'ec2.py',
     'playbook' : 'prod',
     'hosts'    : 'tag_Name_metod_web_instance'
  },
  'preprod': {
     'inventory': 'ec2.py',
     'playbook' : 'preprod',
     'hosts'    : 'tag_Name_metod_preprod_server'
  },
  'yourself': {
     'inventory': 'ec2.py',
     'playbook' : 'inframanager',
     'hosts'    : 'tag_Name_metod_infra_manager'
  },
}

module.exports = (robot) ->
  robot.respond /update (prod|preprod|yourself)( limit (\w*))?( only (\w*(,\w*)*))?( skip (\w*(,\w*)*))?( with (\w*:.*(,\w*:.*)*))?/i, (msg) ->
    target = msg.match[1]
    invfile = "inventory/" + settings[target]['inventory']
    playbook = settings[target]['playbook']
    cwd = settings['path']

    msg.send msg.random marvin_quotes

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

    if msg.match[2]
      limit = msg.match[3].trim()
    if msg.match[4]
      tags = msg.match[5].trim().split ","
    if msg.match[7]
      skip_tags = msg.match[8].trim().split ","
    if msg.match[10]
      vars = msg.match[11].trim().split ","
      varsJsonString = {}
      i = 0
      while i < vars.length
        eltArray = vars[i].trim().split(':')
        varsJsonString[eltArray[0]] = eltArray[1]
        i++
      varsJsonObj = JSON.parse JSON.stringify(varsJsonString)

    playbook = (new (Ansible.Playbook)).inventory(invfile).playbook(playbook)
    message = "updating: #{target}"
    if (limit?)
      playbook = playbook.limit(limit)
      message = message + " limiting to #{limit}"
    if (tags?)
      playbook = playbook.tags(tags)
      message = message + " only with #{tags}"
    if (skip_tags?)
      playbook = playbook.skipTags(skip_tags)
      message = message + " without #{skip_tags}"
    if (vars?)
      playbook = playbook.variables(varsJsonObj)
      message = message + " replacing #{vars}"

    msg.send message

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
