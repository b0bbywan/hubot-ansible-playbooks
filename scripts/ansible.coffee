# Description:
#   A hubot script for launching ansible playbooks
#
# Commands:
#   hubot update <environment> [only <tags>] [skip <tags>] - Execute the playbook on the host
#
# Author:
#   Mathieu Réquillart

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
     'playbook' : 'prod.yml'
  },
  'preprod': {
     'inventory': 'ec2.py',
     'playbook' : 'preprod.yml'
  },
  'hubot': {
     'inventory': 'ec2.py',
     'playbook' : 'inframanager.yml'
  },
}

startsWith = (needle) ->
  (haystack) ->
    `haystack.slice(0, needle.length) == needle`

startsWithSkip = startsWith('skip')

startsWithOnly = startsWith('only')

module.exports = (robot) ->
 robot.respond /update (prod|preprod|hubot)( only (\w*(,\w*)*))?( skip (\w*(,\w*)*))?$/i, (msg) ->
    target = msg.match[1]
    invfile = settings['path'] + "inventory/" + settings[target]['inventory']
    playbook = settings['path'] + settings[target]['playbook']
    cwd = settings['path']

    if msg.match[2]
      tags = msg.match[3].trim()
    if msg.match[5]
      skip_tags = msg.match[6].trim()

    @exec = require('child_process').exec
    msg.send msg.random marvin_quotes
    if (tags?) and (skip_tags?)
      msg.send "updating: #{target} limiting to #{tags} without #{skip_tags}"
      command = "ansible-playbook -i #{invfile} #{playbook} --tags #{tags} --skip-tags #{skip_tags}"
    else if (tags?) and not (skip_tags?)
      msg.send "updating: #{target} limiting to #{tags}"
      command = "ansible-playbook -i #{invfile} #{playbook} --tags #{tags}"
    else if not (tags?) and (skip_tags?)
      msg.send "updating: #{target} without #{skip_tags}"
      command = "ansible-playbook -i #{invfile} #{playbook} --skip-tags #{skip_tags}"
    else if not (tags?) and not (skip_tags?)
      msg.send "updating: #{target}"
      command = "ansible-playbook -i #{invfile} #{playbook}"

    @exec command, {cwd: cwd}, (error, stdout, stderr) ->
      msg.send stdout
