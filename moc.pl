#!/usr/bin/perl -w
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#	simple moc now playing/controlling script for irssi
#	
#	a patch for moc is available here
#	http://pdes-net.org/x-haui/archives/2008/08/10/shufflerepeat_patch_for_moc/index.html
#
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
$VERSION = '1.00';
%IRSSI = (
    authors     => 'Haui',
    contact     => 'haui45@web.de',
    name        => 'mocnp',
    description => 'Irssi moc now playing script',
    license     => 'GPL',
);

my @array;
my %info;
my $string;
my $in;

#uncomment this, if you're sure of having moc installed
`which mocp` or die "fatal....mocp executable not found! Get it from http://moc.daper.net";

# set $pidfile manually if this fails....
my $home = $ENV{"HOME"} || die "couldn't determine your home directory..." ;
my $pidfile = $home . "/.moc/pid";


sub irssi_stuff {
	# server - the active server in window
	# witem - the active window item (eg. channel, query)
	#         or undef if the window is empty
	my ($data, $server, $witem) = @_;
	if ($data) {
		help();
		return ;
	} 
	if ((my $ret = moc()) < 0){
		Irssi::print("mocp isn't playing") if ($ret eq -2);
		Irssi::print("moc's not running, use /start to start the server") if ($ret eq -1);
		return;
	}
	$string =~ s#`#'#g;
	if (!$server || !$server->{connected}) {
		Irssi::print("Not connected to server");
		return;
	}
	elsif ($witem && ($witem->{type} eq "CHANNEL" ||
			$witem->{type} eq "QUERY")) {
		# there's query/channel active in window
		$witem->command("ME $string");
	} else {
		#print songinfo even if you're viewing the server-window
		Irssi::print("No active channel/query in window");
		Irssi::print("moc $string");
	}    
}
# retrieve infos about the currently played song by parsing `mocp -i` & write it to %info
sub moc {
	#check if moc is running
	if (checkplaying() eq -1) {
		return -1;
	}

	@array = `mocp -i`;
	foreach my $line (@array){
		if ($line =~ m/^State:/){
			$info{"state"} = $line; 
			$info{"state"} =~ s/State: //; 
			chomp $info{"state"};
		} 
		if ($line =~ m/^SongTitle:/){
			$info{"title"} = $line;
			$info{"title"} =~ s/SongTitle: //; 
			chomp $info{"title"};
		} 
		if ($line =~ m/^Artist/){
			$info{"artist"} = $line;
			$info{"artist"} =~ s/Artist: //;
			chomp $info{"artist"};
		} 
		if ($line =~ m/^Album/){
			$info{"album"} = $line;
			$info{"album"} =~ s/Album: //;
			chomp $info{"album"};
		} 
		if ($line =~ m/^TotalTime/){
			$info{"total"} = $line; 
			$info{"total"} =~ s/TotalTime: //;
			chomp $info{"total"};
		} 
		if ($line =~ m/^CurrentTime/){
			$info{"current"} = $line;
			$info{"current"} =~ s/CurrentTime:[ ]*//;
			chomp $info{"current"};
		} 
		if ($line =~ m/^Bitrate:/){
			$info{"bitrate"} = $line;
			$info{"bitrate"} =~ s/Bitrate: //;
			chomp $info{"bitrate"};
		} 
		if ($line =~ m/^Rate:/){
			$info{"rate"} = $line;
			$info{"rate"} =~ s/Rate: //;
			chomp $info{"rate"};
		} 
		if ($line =~ m/^Shuffle:/){
			$info{"shuffle"} = $line;
			$info{"shuffle"} =~ s/Shuffle: //;
			chomp $info{"shuffle"};
		} 
		if ($line =~ m/^Repeat:/){
			$info{"repeat"} = $line;
			$info{"repeat"} =~ s/Repeat: //;
			chomp $info{"repeat"};
		} 
		if ($line =~ m/^File: /) {
			$info{"file"} = $line;
			chomp($info{'file'});
			$info{"file"} =~ s/File: //;
			chomp $info{"file"};
			# it's an internetstream
			if ($info{"file"} =~ m/^http:\/\//){
				$in = 1;
			}
			$info{'file'} =~ s#`#\\`#g;
			$info{"type"} = `file \"$info{'file'}\"`;  #filetype
			$info{'file'} =~ s#\\`#`#g;
			my $tmp = -s $info{'file'};
			$info{"size"} = sprintf("%.2f MB", ((($tmp) / 1024) / 1024)) ;
		}
		
	}
	if ($info{'type'} =~ /mp3/i){
		$info{'type'} = "mp3";
	}
	elsif ($info{'type'} =~ /ogg/i){
		$info{'type'} = "ogg";
	}
	elsif ($info{'type'} =~ /wav/i){
		$info{'type'} = "wav";
	}
	elsif ($info{'type'} =~ /wma/i){
		$info{'type'} = "wma";
	}
	else{ 
		$info{'type'} = "unknown";
	}

	if (($info{"state"} =~ m/STOP|PAUSE/)){
		return -1 if ($info{'state'} =~ m/STOP/);
		return -2 if ($info{'state'} =~ m/PAUSE/);
	}

	if ($in eq 1){
		stream();
		return;
	}

	$string = "is currently playing: $info{'artist'} - $info{'title'} on \"$info{'album'}\" | [$info{'current'}/$info{'total'}] " . 
			"| [$info{'bitrate'}] | [$info{'rate'}] | [$info{'size'}] | [$info{'type'}]" ;
	
}

sub checkplaying {
	return -1 unless (-e $pidfile);
	return 0;
}

sub stream {
	$string = "is currently playing: $info{'artist'} - $info{'title'} | [$info{'current'}] " . 
			"| [$info{'bitrate'}] | [$info{'rate'}] | [$info{'file'}] | [Streaming...]" ;
	$in = 0;
}

sub next {
	if (checkplaying() == -1){
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -f");
	return 0;
}

sub prev {
	if (checkplaying() == -1) {
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -r");
	return 0;
}

sub shuffle {
	my ($data, $server, $witem) = @_;
	if (checkplaying() == -1){
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -t shuffle &>/dev/null");
	moc();
	return unless (defined ($info{'shuffle'}));
	if (!$server || !$server->{connected}) {
		Irssi::print ("Shuffle: $info{'shuffle'}");
	}
	elsif ($witem && ($witem->{type} eq "CHANNEL" ||
			$witem->{type} eq "QUERY")) {
		# there's query/channel active in window
		$witem->command("echo Shuffle: $info{'shuffle'}");
	}
	else{
		Irssi::print ("Shuffle: $info{'shuffle'}");
	}

	return 0;
}

sub stop {
	if (checkplaying() == -1){
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -P");
	return 0;
}

sub play {
	if (checkplaying() == -1) {
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -U");
	return 0;
}

sub start {
	system("mocp -S &> /dev/null");
	system("mocp -p &> /dev/null");
	return 0;
}

sub repeat {
	my ($data, $server, $witem) = @_;
	if (moc() == -1){
		Irssi::print "moc's not running, use /start to start the server";
		return;
	}
	system("mocp -t repeat &>/dev/null");
	moc();
	return unless (defined ($info{'repeat'}));
	if (!$server || !$server->{connected}) {
		Irssi::print ("Repeat: $info{'repeat'}");
	}
	elsif ($witem && ($witem->{type} eq "CHANNEL" ||
			$witem->{type} eq "QUERY")) {
		# there's query/channel active in window
		$witem->command("echo Repeat: $info{'repeat'}");
	}
	else{
		Irssi::print ("Repeat: $info{'repeat'}");
	}
	return 0;

}
sub help {
	Irssi::print(" mocp help: \n" . 
			" /mocnp     -  prints the song currently played by moc in the current channel/query\n" .
			" /next      -  next song\n" .
			" /prev      -  previous song\n" .
			" /shuffle   -  Turns shuffle on/off (requires >=mocp 2.5)\n" .
			" /repeat    -  Turns repeat on/off (requires >=mocp 2.5)\n" .
			" /start     -  Starts moc if it's not running or if it's in mode \"stop\"\n" .
			" /play      -  Play... \n" .
			" /pause     -  Pause the current song\n" .
			" /stop      -  Stop moc\n" .
			" /mocp help -  Display this help \n" .
			"Please note that notifications about shuffle/repeat will only work with a patched version of moc...");

	return;
}
Irssi::command_bind('mocnp', 'irssi_stuff');
Irssi::command_bind('next', 'next');
Irssi::command_bind('n', 'next');
Irssi::command_bind('prev', 'prev');
Irssi::command_bind('p', 'prev');
Irssi::command_bind('shuffle', 'shuffle');
Irssi::command_bind('repeat', 'repeat');
Irssi::command_bind('play', 'play');
Irssi::command_bind('start', 'start');
Irssi::command_bind('pause', 'stop');
Irssi::command_bind('stop', 'stop');
Irssi::command_bind('mocnp help', 'help');
