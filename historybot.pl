use strict;
use Irssi;
use POSIX qw(strftime);
use TokyoCabinet;
use JSON::Parse qw(json_file_to_perl); 
use vars qw($VERSION %IRSSI);
$VERSION = '1.01';
%IRSSI = (
    authors     => 'A.Michaelis',
    contact     => 'support@hyperplane.org',
    name        => 'historybot',
    description => "Simple channel(s) message rolling history save and dump script for channel ops.",
    license     =>  "MIT",
    url         => 'https://www.hyperplane.org',
    changed     => 'Tue Oct 18, 2016',
);

#
# A basic script that saves a rolling history based on a retention 
# parameter for all channels listed in the config. 
#
# A nick within the channel may send the message !history
# to the channel (everyone sees the request for history ) 
# and then the script will send the number of retained messages 
# for that channel via a private message to the requesting nick. 
#

#  The channel configs (loaded from the external json config) 
my @channels;
# The tokyo cabinet key value store handle 
my $hdb; 
# The tokyo cabinet key value store file path
my $hfile; 
# The absolute maximum length of a message that can be saved.
my $maxmsglen = 384; 

my $debug = 0; 

########################################################################
sub historybot_load_conf
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
   @channels = @{ $cnf->{'channels'} };
   $hfile = $cnf->{'tokyocab'};
   if($hfile =~  m/^\~/) {
      $hfile = $ENV{"HOME"} . substr $hfile, 1;
   }
   else {
      $hfile = $hfile;
   }
   return 1;
}

########################################################################
sub historybot_init
{
   my $win = Irssi::window_find_refnum(1);
   my $cnffile; 
   Irssi::settings_add_str("historybot", "historybot.config", "None");
   my $cnfstr = Irssi::settings_get_str("historybot.config");
   if($cnfstr eq "None") { 
      $win->print("No historybot.config set yet. Update the historybot.config");
      $win->print("setting,  /save, then fill in config file (json format)");
      $win->print("historybot.config = \"~/.irssi/hisbot.cnf\"");
      Irssi::settings_set_str("historybot.config", "~/.irssi/hisbot.cnf");
      open my $fh, ">", $ENV{"HOME"}. "/.irssi/hisbot.cnf";
      print $fh '{ "channels": [ {"name" : "chan1", "retain" :  32, "count" : 0} ], "tokyocab": "~/.irssi/chansmsg.tct" }';
      close $fh;
      return;
   }
   # Get the config info (note this is outside the irssi config)
   historybot_load_conf($cnfstr);
   $hdb = TokyoCabinet::HDB->new();
   #TODO: work on reloading history on restart (the whole point of using tokyo cab...)
   if( !$hdb->open($hfile, $hdb->OWRITER | $hdb->OCREAT)) {
      my $ecode = $hdb->ecode();
      printf STDERR ("TokyoCabinet init error: %s", $hdb->errmsg($ecode));
   }
} 

########################################################################
sub UNLOAD 
{
   if( defined $hdb ) {
      if( !$hdb->close() ) {
         my $ecode = $hdb->ecode();
         printf STDERR ("TokyoCabinet closeup error: %s", $hdb->errmsg($ecode));
      }
   }
   #TODO: work on save counts for reload later
}

########################################################################
sub sig_public 
{
   my ($server, $msg, $nick, $address, $target) = @_;
   my ($strm, $msgkey, $ecode, $e, $i);

   # chop string off just in case...
   $msg = substr($msg, 0, $maxmsglen);

   foreach my $channel ( @channels  ) {
      if ( $target eq "#".$channel->{"name"}) {
         if ($msg =~ /^[\t ]*\!history/i ) {
            # TODO: work on nick request rate limit
            $server->command( "MSG ".$nick." ## start history for ".$channel->{"name"}." requested ". strftime "%m/%d/%Y %H:%M", localtime);
            if($channel->{"count"} < $channel->{"retain"}) { 
               $i = 0;
               $e = $channel->{"count"};
            }
            else {
               $i = $channel->{"count"} - $channel->{"retain"};
               $e = $i + $channel->{"retain"};
            }
            if ($debug  == 1) { 
            	printf "DEBUG : historybot request channel=".$channel->{"name"}.", count=".
                       $channel->{"count"}." , retain=".$channel->{"retain"}.", start=".$i.", stop=$e"; 
            }
            for (  ; $i < $e; $i++) {
               $msgkey = $channel->{"name"} . sprintf("%d", $i % $channel->{"retain"} );
               $strm = $hdb->get($msgkey);
               if( defined( $strm ) ) {
                  $server->command( "MSG ".$nick." ".$strm);
               } 
            }
            $server->command("MSG ".$nick." ## end history for ".$channel->{"name"});
         }
         else {
            $strm = $nick."@".$channel->{"name"}." ".$msg;
            $msgkey = $channel->{"name"} . sprintf("%d", $channel->{"count"} % $channel->{"retain"});  
            $channel->{"count"} += 1;
            $hdb->tranbegin(); 
            if ($debug  == 1) {
            	printf "DEBUG : historybot saving at ".$msgkey." : ".$strm;
            }
            if ( !$hdb->put($msgkey,  $strm) ) {
               $ecode = $hdb->ecode();
               printf STDERR ("TokyoCabinet put error: %s", $hdb->errmsg($ecode));
            }
            $hdb->trancommit(); 
         }
      }
   }
}

historybot_init();
Irssi::signal_add_last('message public', 'sig_public');

