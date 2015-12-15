settings = {
  'path': '/home/ansible/metod-deploy/',
  'prod': {
     'inventory': 'prod',
     'playbook' : 'prod.yml'
  },
  'preprod': {
     'inventory': 'preprod',
     'playbook' : 'preprod.yml'
  },
}


module.exports = (robot) ->
 robot.respond /ansible (.*) (.*)$/i, (msg) ->

    target = msg.match[1]
    tags = msg.match[2]
    @exec = require('child_process').exec
    msg.send "updating: #{target} limiting to #{tags}"
    cwd = settings['path']
    invfile = settings['path'] + "inventory/" + settings[target]['inventory']
    playbook = settings['path'] + settings[target]['playbook']
    command = "ansible-playbook -i #{invfile} #{playbook} --tags #{tags}" 

    @exec command, {cwd: cwd}, (error, stdout, stderr) ->
      msg.send stdout
