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
#	this script sets the reply for "ctcp version requests" to the song
#	currently played by moc

use strict;
use Irssi;
my $VERSION = '1.00';
my %IRSSI = (
    authors     => 'Haui',
    contact     => 'haui45@web.de',
    name        => 'mocctcp',
    description => 'ctcp version reply script',
    license     => 'GPL',
);
my $installed=1;

`fortune bofh-excuses 2> /dev/null` or $installed=0;


sub ctcp() {
	if ($installed == 0){
		Irssi::print "fortune not installed...";
		Irssi::settings_set_str('ctcp_version_reply', "BOFH excuse #171: NOTICE: alloc: /dev/null: filesystem full");
	}
	else{
		my $string=`fortune bofh-excuses`;
		$string =~ s#\n# #g;
		Irssi::settings_set_str('ctcp_version_reply', "$string");
	}
}

Irssi::signal_add('ctcp msg version', 'ctcp');


