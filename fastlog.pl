#!/usr/bin/perl -w

# a fast log entry program.  inspired by DL3CB's FLE.
#
# 2-clause BSD license.

# Copyright 2014,2022,2023 Chris Ruvolo (K2CR). All rights reserved.
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
my $freq = undef;
my $mode = undef;
my $mycall = undef;
my $mygrid = undef;
my $oper = undef;
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
			print STDERR "freq cleared\n" if defined $freq and not defined $quiet;
			$freq = undef if defined $freq;
		};
	} elsif (/^\s*mode\s+(\w+)/i) {
		my $tmp = $1;
		if (grep { /$tmp/i } @modes) {
			$mode = $tmp;
			print STDERR "mode set: $mode\n" unless defined($quiet);
		}
	} elsif (m|^\s*oper\s+([A-Z0-9/]+)|i) {
		$oper = uc $1;
		print STDERR "oper set: $oper\n" unless defined($quiet);
	} elsif (m|^\s*mycall\s+([A-Z0-9/]+)|i) {
		$mycall = uc $1;
		print STDERR "mycall set: $mycall\n" unless defined($quiet);
	} elsif (m|^\s*mygrid\s+([A-R]{2}[0-9]{2}([a-x]{2})?)|i) {
		$mygrid = $1;
		print STDERR "mygrid set: $mygrid\n" unless defined($quiet);
	} elsif (m|^\s*(freq)?\s*([0-9]+\.[0-9]+)|i) {
		$freq = $2;
		my $b = getBandForFreq($freq);
		$band = $b if defined $b;
		print STDERR "band set: $band\n" if defined $b and not defined($quiet);
		print STDERR "freq set: $freq\n" unless defined($quiet);
	} elsif (/\s*(delete|drop|error)/i) {
		my ($date, $time, $call, $band, $mode, $sentrst, $myrst, $mycall, $oper, $comment, $siginfo) = split(/\|/, pop(@qsos));
		print STDERR "deleted qso: $date $time $call $band $mode\n"
			unless defined($quiet);
	} elsif (m|^\s*(\d{0,4})?\s*([0-9]+\.[0-9]+)?\s*([A-Z0-9/]{3,})\s*(\d{2,3})?\s*(@\d{2,3})?\s*(#.*)?$|i) {
		# 51 3.515 dl4mcf 579 @559 #good contact
		# 1: 51
		# 2: 3.515
		# 3: dl4mcf
		# 4: 579
		# 5: @559
		# 6: #good contact
		my $timefrag = $1;
		my $qsofreq = $2;
		my $call = uc $3;
		my $sentrst = $4;
		my $myrst = $5;
		my $comment = $6;
		my $grid = "";
		$comment =~ s/^#\s*/#/ if defined $comment;
		$comment =~ s/\s*$// if defined $comment;

		my $b = getBandForFreq($qsofreq) if defined $qsofreq;
		$band = $b if defined $b;
		$qsofreq = $freq if defined $freq and not defined $qsofreq;

		if (!defined($band)) {
			print STDERR "error: band must be set.\n";
			next;
		}
		if (!defined($mode)) {
			print STDERR "error: mode must be set.\n";
			next;
		}

		if (! ($call =~ m|^\s*([a-z]*[0-9]*/)?(\d?[a-z]{1,2}[0-9Øø]{1,4}[a-z]{1,4})(/[a-z]*[0-9]*)?\s*$|i)) {
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
		$mycall = "" unless defined $mycall;
		$myrst = "" unless defined $myrst;
		$comment = "" unless defined $comment;
		$mygrid = "" unless defined $mygrid;
		$oper = "" unless defined $oper;
		$qsofreq = "" unless defined $qsofreq;
		$myrst =~ s/^@//;
		$comment =~ s/^#//;

		my $siginfo = "";
		if ($comment =~ m/(POTA|PTP)\s+([A-Z0-9]+-\d+)/) {
		  $siginfo = $2;
		}
		if ($comment =~ m/\b([A-R]{2}[0-9]{2}([a-x]{2})?)\b/i) {
		  $grid = $1;
		}

		print STDERR "qso: $date $time $call $qsofreq $band $mode $sentrst $myrst $grid $mycall $mygrid $oper $comment $siginfo\n" unless defined($quiet);
		push(@qsos, join('|', $date, $time, $call, $qsofreq, $band, $mode, $sentrst, $myrst, $grid, $mycall, $mygrid, $oper, $comment, $siginfo));
	} else {
		print STDERR "unknown input: $_\n";
	}
}

# output as adif
print "Log file transcribed by fastlog. https://github.com/cruvolo/fastlog\n";
print "<ADIF_VER:5>2.1.4\n<EOH>\n";
foreach(@qsos) {
	#print "$_\n";
	my ($date, $time, $call, $qsofreq, $band, $mode, $sentrst, $myrst, $grid, $mycall, $mygrid, $oper, $comment, $siginfo) = split/\|/;
	$date =~ s/-//g;
	print "<BAND:", length(uc($band)), ">", uc($band),
	      (length($qsofreq)==0)?"":(" <FREQ:".length($qsofreq).">".$qsofreq),
	      " <MODE:", length(uc($mode)), ">", uc($mode),
	      " <QSO_DATE:8>", $date, " <TIME_ON:4>$time",
	      (length $mycall==0)?"":(" <STATION_CALLSIGN:".length($mycall).">".$mycall),
	      " <RST_SENT:", length($sentrst), ">", $sentrst,
	      (length $mygrid==0)?"":(" <MY_GRIDSQUARE:".length($mygrid).">".$mygrid),
	      " <CALL:", length($call), ">", $call,
	      (length($myrst)==0)?"":(" <RST_RCVD:".length($myrst).">".$myrst),
	      (length($grid)==0)?"":(" <GRIDSQUARE:".length($grid).">".$grid),
	      (length $oper==0)?"":(" <OPERATOR:".length($oper).">".$oper),
	      (length($siginfo)==0)?"":(" <SIG_INFO:".length($siginfo).">".$siginfo),
	      (length($comment)==0)?"":(" <COMMENT:".length($comment).">".$comment),
	      "\n<EOR>\n";
}


sub getBandForFreq {
  my $f = shift;

  return undef if not defined $f or $f == 0.0;

  return "2200m" if $f >= 0.1357 and $f <= 0.1378;
  return "630m" if $f >= 0.472 and $f <= 0.479;
  return "160m" if $f >= 1.8 and $f <= 2.0;
  return "80m" if $f >= 3.5 and $f <= 4.0;
  return "60m" if $f >= 5.06 and $f <= 5.45;
  return "40m" if $f >= 7.0 and $f <= 7.3;
  return "30m" if $f >= 10.1 and $f <= 10.15;
  return "20m" if $f >= 14.0 and $f <= 14.35;
  return "17m" if $f >= 18.068 and $f <= 18.168;
  return "15m" if $f >= 21.0 and $f <= 21.45;
  return "12m" if $f >= 24.890 and $f <= 24.99;
  return "10m" if $f >= 28.0 and $f <= 29.7;
  return "6m" if $f >= 50.0 and $f <= 54.0;
  return "4m" if $f >= 70.0 and $f <= 71.0;
  return "2m" if $f >= 144.0 and $f <= 148.0;
  return "70cm" if $f >= 420.0 and $f <= 450.0;

  print STDERR "ERROR: unknown band for frequency $f\n";
  return undef;
}
