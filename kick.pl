#!/usr/bin/perl

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use vars qw(%IRSSI );
my %IRSSI = (
	'authors'	=>	'Haui',
	'contact'	=>	'haui45@web.de',
	'name'		=>	'kicjuppdiduppk',
	'description'	=>	'this script allows you to kick' . 
				'multiple users :D',
	'license'	=>	'GPL',
	'version'	=>	'0.1',
	'usage'		=>	'/kck user1 user2 user3',
	);

#define your kickreason: /set kmessage REASON
Irssi::settings_add_str("kick", "kmessage", "byebye");
sub kck {
    # server - the active server in window
    # witem - the active window item (eg. channel, query)
    #         or undef if the window is empty
    my ($data, $server, $witem) = @_;

    if (!$server || !$server->{connected}) {
      Irssi::print("Not connected to server");
      return;
    }

    if ($data && $witem && ($witem->{type} eq "CHANNEL")) {
	my @array = split(/ /, $data);
	my $reason = Irssi::settings_get_str("kmessage");
	foreach (@array){
      		$witem->command("/kick $_ $reason");
	}
    } else {
      Irssi::print("Error");
    }
  }

  Irssi::command_bind('kck', 'kck');
