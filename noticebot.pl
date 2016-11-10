use strict;
use Irssi;
use JSON::Parse qw(json_file_to_perl); 
use vars qw($VERSION %IRSSI);
$VERSION = '1.01';
%IRSSI = (
    authors     => 'Andrew Michaelis',
    contact     => 'support@hyperplane.org',
    name        => 'noticebot',
    description => 'Simple applescript notify utility (for a modern MacOS only).',
    license     =>  "MIT",
    url         => 'https://www.hyperplane.org',
    changed     => 'Tue Oct 25 2016'
);

# Globals
my @notenicks;

########################################################################
sub nb_load_conf
{
   my $cnf;
   my ($fname) = @_;
   if($fname =~  m/^\~/) {
      $fname = $ENV{"HOME"} . substr $fname, 1;
   }
   else {
      $fname = $fname ;
   }
   $cnf = json_file_to_perl($fname);
   @notenicks = @{ $cnf->{'nicks'} };
   return 1;
}

########################################################################
# Usage: /notbotconf - Reloads the json config file
sub nb_reload_conf 
{
   my ($data, $server, $witem) = @_;
   my $win = Irssi::window_find_refnum(1);
   my $cnfstr = Irssi::settings_get_str("noticebot.config");
   if($cnfstr ne "None") { 
      $win->print("Reloading $cnfstr ...");
      nb_load_conf($cnfstr);
   }
}

########################################################################
# Usage: /notbotlist - lists the current config
sub nb_list_conf 
{
   my ($data, $server, $witem) = @_;
   my ($nick, $snd);
   my $win = Irssi::window_find_refnum(1);
   foreach my $nn ( @notenicks ) {
      $nick = $nn->{"name"};
      $snd = $nn->{"sound"};
      $win->print("noticebot watch : $nick, $snd");
   }
}

########################################################################
sub nb_init
{
   my $win = Irssi::window_find_refnum(1);
   my $cnffile; 
   Irssi::settings_add_str("noticebot", "noticebot.config", "None");
   my $cnfstr = Irssi::settings_get_str("noticebot.config");
   if($cnfstr eq "None") { 
      $win->print("No noticebot.config set yet. Update the noticebot.config");
      $win->print("setting,  /save, then fill in config file (json format)");
      $win->print("noticebot.config = \"~/.irssi/noticebot.cnf\"");
      Irssi::settings_set_str("noticebot.config", "~/.irssi/noticebot.cnf");
      open my $fh, ">", $ENV{"HOME"}. "/.irssi/noticebot.cnf";
      print $fh '{ "nicks": [ {"name" : "foo", "sound" : "None" } ] }';
      close $fh;
      return;
   }
   # Get the config info (not this is outside the irssi config)
   nb_load_conf($cnfstr);
   Irssi::command_bind('notbotconf', 'nb_reload_conf', "perl extensions");
   Irssi::command_bind('notbotlist', 'nb_list_conf', "perl extensions");
} 

########################################################################
sub sig_notify
{
   my ($server, $msg, $nick, $address, $target) = @_;
   my ($cmd, $msgcl);

   foreach my $nn ( @notenicks ) {
      if ( $nick eq $nn->{"name"}) {
         $msg =~ s/'|"/ /g; 
         $msgcl = substr($msg, 0, 16)." ...";
         $cmd =  "\'display notification \"".$msgcl."\" with title \"irssi\" subtitle \"From nick ".$nick."\"";
         if ( $nn->{"sound"} ne "None") {
            $cmd = $cmd . " sound name \"".$nn->{"sound"}."\"\'";
         }
         else {
            $cmd = $cmd . "\'";
         }
         system("osascript -e ".$cmd);
      }
   }
}

nb_init();
Irssi::signal_add_last('message irc notice', 'sig_notify');
Irssi::signal_add_last('message public', 'sig_notify');

