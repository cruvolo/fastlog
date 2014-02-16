#!/usr/bin/perl -w

use strict;
use POSIX qw(strftime);

my $date = strftime("%Y-%m-%d", gmtime);
my $time = strftime("%H%M", gmtime);
my $band = undef;
my $mode = undef;
my @bands = ("630m", "160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "2m", "70cm");
my @modes = ("SSB", "CW", "RTTY", "PSK31", "AM", "PHONE", "DATA");
my @commands = ("date", "band", "mode", "help");
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
		}
		if (!defined($mode)) {
			print STDERR "error: mode must be set.\n";
		}

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

