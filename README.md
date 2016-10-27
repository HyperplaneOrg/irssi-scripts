irssi-scripts
==============

A few toys that may, or may not, be a useful addition for your [irssi irc client](https://irssi.org)

Scripts
-------
* historybot.pl - a basic utility bot that saves a rolling history of messages 
  based on a retention parameter for all channels listed in the config. 
  A nick may send the message !history to the channel (everyone will see the 
  request for history) and then this script will send the number of retained 
  messages for that channel via a private message to the requesting nick. 

  One might use this in a small channel with an op's client that has a 
  persistent connection, to one or more channels, to assist nicks that 
  drop in and out (roam) frequently that would like to retrieve messages 
  they might have missed during the dropout.

  Note: this utility uses [Tokyo Cabinet](http://fallabs.com/tokyocabinet/), via the Perl
  extension, to store the rolling histories.  
   
