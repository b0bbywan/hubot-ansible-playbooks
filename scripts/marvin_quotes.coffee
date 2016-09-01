# Description:
#   A hubot script to quote marvin from H2G2
#
# Commands:
#   just quote marvin from H2G2
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


module.exports = (robot) ->

  robot.on "ansible_update", (data) ->
    randIndex = Math.floor((Math.random()*marvin_quotes.length)+1)
    data.msg.send marvin_quotes[randIndex - 1]

  robot.hear /marvin/i, (msg) ->
    msg.send msg.random marvin_quotes
