# hubot-ansible-playbooks

A hubot script to launch ansible playbooks

hubot-ansible-playbooks relies on *node-ansible*.

See [`src/ansible.coffee`](src/ansible.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-ansible-playbooks --save`

Then add **hubot-ansible-playbooks** to your `external-scripts.json`:

```json
[
  "hubot-ansible-playbooks"
]
```

Ansible has to be installed on the same host as your *Hubot*, and your playbooks must be accessible by the system user running *Hubot*.

So if you have a repository for ansible and for hubot and a playbook for hubot, you can create a playbook for Hubot to update himself. #MuchMeta

## Environment variables

- `HUBOT_ANSIBLE_SETTINGS`: location of your settings file
- `HUBOT_ANSIBLE_VERBOSE`: set to display ok and skipped tasks
- `HUBOT_SLACK_BOTNAME`: name of your Slack bot

## Settings File

The settings file is a javascript module and looks likes this:

```javascript
module.exports = {
  path: "/home/ansible/deployer/",
  admin_users: [
    "U6YTSD2BZ",
    ...
  ],
  prod: {
    inventory: "ec2.py",
    playbook : "prod",
    authorized_users: ["U85LB1FPV", ...]
  },
  ...
}
```

- `path`: path to your ansible playbook folder
- `admin_users`: list of slack user id who can use any playbook
- Any other valid json key can be used as a nickname for your playbook
- `inventory`: name of your inventory file. Relatively, the script considers that the inventory filed are stored in an `inventory` folder as recommanded by Ansible. Absolute path can also be used.
- `playbook`: name of your playbook, without the extension
- `authorized_users`: list of slack user id who can use this playbook

## Sample Interaction

```
user1>> hubot update prod limit deployer only ansible skip requirements with gitRepoVersion:feature
hubot>> updating: **prod** limiting to **deployer** with only **ansible** skipping **requirements** replacing **gitRepoVersion:feature**
```

In this case, hubot will execute the *prod* playbook, as defined in your settings file. It will only execute the tags and role associated to the *deployer* host(s), the tasks and role containing the *ansible* tags, but not those containing the *requirements* tags. The *gitRepoVersion* variable is overriden to use the *feature* branch (or commit or tag)

## Various

To be more explcit, common feedback from ansible are enhanced with slack emojis. If there's interest, those might become environment variables to be configured.

To relieve the chan and comply with slack ratio sending limit, all messages are filtered. *ok* and *skipped* tasks are not displayed. If a message isn't handled by the filters it might come in a strange order. You can check the logs and open an issue.

## ToDo

Unit tests.

Implement more node-ansible options, such as askPassword

Be less dependant on Slack

## NPM Module

https://www.npmjs.com/package/hubot-ansible-playbooks
