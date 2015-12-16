# Description:
#   A hubot script for launching ansible playbooks
#
# Commands:
#   hubot ansible <env> [<tags>][ skip <tags>] - Execute the command on the hosts
#
# Author:
#   Mathieu Réquillart

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

module.exports = (robot) ->
 robot.respond /ansible (prod|preprod|hubot) (skip (.*)|.*?)?( skip (.*))?$/i, (msg) ->
    target = msg.match[1]
    invfile = settings['path'] + "inventory/" + settings[target]['inventory']
    playbook = settings['path'] + settings[target]['playbook']
    cwd = settings['path']

    if msg.match[2].trim()
      if not startsWithSkip(msg.match[2].trim())
        tags = msg.match[2].trim()
      else
        skip_tags = msg.match[3].trim()

    if msg.match[3]
      skip_tags = if startsWithSkip(msg.match[3].trim()) then msg.match[4].trim()

    @exec = require('child_process').exec

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
