#!/usr/bin/perl -w

# a fast log entry program.  inspired by DL3CB's FLE.
#
# 2-clause BSD license.

# Copyright 2014,2022 Chris Ruvolo (K2CR). All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# 	this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
# 	this list of conditions and the following disclaimer in the
# 	documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY CHRIS RUVOLO ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL CHRIS RUVOLO OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of Chris Ruvolo.

use strict;
use utf8;
use feature 'unicode_strings';
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use POSIX qw(strftime);

my $date = strftime("%Y-%m-%d", gmtime);
my $time = strftime("%H%M", gmtime);
my $band = undef;
my $mode = undef;
my @bands = ("630m", "160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "4m", "2m", "70cm");
my @modes = ("SSB", "CW", "RTTY", "PSK31", "FM", "AM", "PHONE", "DATA");
my @qsos;
my $quiet = undef;

my $i = 0;
while ($i <= $#ARGV) {
	if ($ARGV[$i] =~ /-q|--quiet/) {
		shift;
		$quiet = 1;
	}
	$i++;
}

while (<>) {
	chomp;
	next if (/^\s*#/);
	next if (/^\s*$/);
	if (/^\s*date\s+(\d{4}-\d{2}-\d{2})/i) {
		$date = $1;
		print STDERR "date set: $date\n" unless defined($quiet);
	} elsif (/^\s*band\s+(\d+c?m?)/i) {
		my $tmp = $1;
		$tmp =~ s/(\d+)$/$1m/;
		if (grep { /$tmp/i } @bands) {
			$band = $tmp;
			print STDERR "band set: $band\n" unless defined ($quiet);
		};
	} elsif (/^\s*mode\s+(\w+)/i) {
		my $tmp = $1;
		if (grep { /$tmp/i } @modes) {
			$mode = $tmp;
			print STDERR "mode set: $mode\n" unless defined($quiet);
		}
	} elsif (/\s*(delete|drop|error)/i) {
		my ($date, $time, $call, $band, $mode, $sentrst, $myrst, $comment) =
			split(/\|/, pop(@qsos));
		print STDERR "deleted qso: $date $time $call $band $mode\n"
			unless defined($quiet);
	} elsif (/^(\d{0,4})?\s*(\w{3,})\s*(\d{2,3})?\s*(@\d{2,3})?\s*(#.*)?$/) {
		# 51 dl4mcf 579 @559 #good contact
		# 1: 51
		# 2: dl4mcf
		# 3: 579
		# 4: @559
		# 5: #good contact
		my $timefrag = $1;
		my $call = $2;
		my $sentrst = $3;
		my $myrst = $4;
		my $comment = $5;

		if (!defined($band)) {
			print STDERR "error: band must be set.\n";
			next;
		}
		if (!defined($mode)) {
			print STDERR "error: mode must be set.\n";
			next;
		}

		if (! ($call =~ /^\s*(\d?[a-z]{1,2}[0-9Øø]{1,4}[a-z]{1,4})\s*$/i)) {
			print STDERR "error: invalid callsign: $call\n";
			next;
		}
		$call =~ s/[Øø]/0/g;

		$time = substr($time,0,4-length($timefrag)) . $timefrag;
		if (uc($mode) eq "SSB") {
			$sentrst = "59" unless defined $sentrst;
		} else {
			$sentrst = "599" unless defined $sentrst;
		}
		$myrst = "" unless defined $myrst;
		$comment = "" unless defined $comment;
		$myrst =~ s/^@//;
		$comment =~ s/^#//;

		print STDERR "qso: $date $time $call $band $mode $sentrst $myrst $comment\n" unless defined($quiet);
		push(@qsos, join('|', $date, $time, $call, $band, $mode, $sentrst, $myrst, $comment));
	}
}

# output as adif
print "Log file transcribed by fastlog. https://github.com/cruvolo/fastlog\n";
print "<ADIF_VER:4>1.00\n<EOH>\n";
foreach(@qsos) {
	#print "$_\n";
	my ($date, $time, $call, $band, $mode, $sentrst, $myrst, $comment) =
		split/\|/;
	$date =~ s/-//g;
	print "<QSO_DATE:8>", $date, " <TIME_ON:4>$time <CALL:",
		length(uc($call)), ">", uc($call), " <BAND:",
		length(uc($band)), ">", uc($band), " <MODE:",
		length(uc($mode)), ">", uc($mode), " <RST_SENT:",
		length($sentrst), ">", $sentrst,
		(length($myrst)==0)?"":(" <RST_RCVD:".length($myrst).">".$myrst),
		(length($comment)==0)?"":(" <COMMENT:".length($comment).">".$comment),
		"\n<EOR>\n";
}

