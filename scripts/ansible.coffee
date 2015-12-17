# Description:
#   A hubot script for launching ansible playbooks
#
# Commands:
#   hubot update <environment> [only <tags>] [skip <tags>] - Execute the playbook on the host
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

startsWithOnly = startsWith('only')

module.exports = (robot) ->
 robot.respond /update (prod|preprod|hubot)( only (\w*))?( skip (\w*))?$/i, (msg) ->
    target = msg.match[1]
    invfile = settings['path'] + "inventory/" + settings[target]['inventory']
    playbook = settings['path'] + settings[target]['playbook']
    cwd = settings['path']

    if msg.match[2]
      if startsWithOnly(msg.match[2].trim())
        tags = msg.match[3].trim()
    if msg.match[4]
      if startsWithSkip(msg.match[4].trim())
       skip_tags = msg.match[5].trim()

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
