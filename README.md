fastlog
=======

A quick and dirty ham radio log transcription program, inspired by DL3CB's
"FLE": http://df3cb.com/fle/

Input is text, output is [ADIF log file format](https://www.adif.org/),
compatible with [version 2.1.4](https://www.adif.org/adif214.htm).

## syntax

```
date YYYY-MM-DD
```
Sets the QSO date for new entries.  Note that this is ISO date format (this
differs from DL3CB's FLE syntax).

```
mycall <callsign>
```
Sets the callsign that was used on the air.

```
mygrid <gridsquare>
```
Sets the grid square the station was operating from.

```
band <wavelength>
```
Sets the band for new entries.  Accepted bands: 630m, 160m, 80m, 60m, 40m, 30m,
20m, 17m, 15m, 12m, 10m, 6m, 4m, 2m, 70cm.  Note that the 'm' can be omitted, except
for 70cm.

```
mode <mode>
```
Sets the mode for new entries.  Accepted modes: SSB, CW, RTTY, PSK31, AM,
PHONE, DATA.  Case insensitive.  Note that the use of the "mode" keyword
differs from DL3CB's FLE syntax.

```
oper <callsign>
```
Sets the operator callsign.  Use this when running a multi-op station to
indicate the control operator for the following QSOs.

```
delete
drop
error
```

Removes the last qso logged.

```
[time fragment] <callsign> [sent rst] [@received rst] [#comment]
```
Adds a QSO entry to the log.  Time fragment adjusts the rightmost bits of the
timestamp first.  For example, if the last time entered was 2311, and the user
enters "3 W1AW", the timestamp will be updated to "2313" for the W1AW qso.

If a RST is omitted, "599" is used as a default, or "59" if the qso is for SSB
mode.

## POTA support

If a QSO comment has the designator `POTA <park number>` or `PTP <park number>`,
then the data will be placed into the `SIG_INFO` ADIF field for compatibility
with [Parks On the Air](https://pota.app/).

Example:

```
1646 K5ALA  55 @58 # PTP K-3601
  47 KE8SZL 59 @59 # PTP K-4316
  48 KA1DMA 59 @55 # PTP K-1073
```

## Gridsquare support for VHF or Satellites

If a QSO comment has a valid 4 or 6 digit gridsquare, that grid square will be recorded in the ADIF `<GRIDSQUARE` field.

Example:

```
1946 WB2AMU # FN30
1958 KN3B   # FN11
2010 N1DPM  # FN32 MA
```

## execution

The script accepts a -q or --quiet option.  It can be run interactively or
reading a file.

```
$ ./fastlog.pl -q sampleinput.txt
Log file transcribed by fastlog. https://github.com/cruvolo/fastlog
<ADIF_VER:5>2.1.4
<EOH>
<QSO_DATE:8>20101130 <TIME_ON:4>2347 <CALL:5>DF3CB <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2348 <CALL:6>DL6RAI <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2348 <CALL:5>DJ2MX <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2351 <CALL:6>DL4MCF <BAND:3>20M <MODE:2>CW <RST_SENT:3>579 <RST_RCVD:3>559 <COMMENT:12>Good contact
<EOR>
<QSO_DATE:8>20101201 <TIME_ON:4>0005 <CALL:5>DH1TW <BAND:3>15M <MODE:3>SSB <RST_SENT:2>59
<EOR>
```

```
$ ./fastlog.pl sampleinput.txt
date set: 2010-11-30
band set: 20m
mode set: cw
qso: 2010-11-30 2347 df3cb 20m cw 599
qso: 2010-11-30 2348 dl6rai 20m cw 599
qso: 2010-11-30 2348 dj2mx 20m cw 599
qso: 2010-11-30 2351 dl4mcf 20m cw 579 559 Good contact
date set: 2010-12-01
band set: 15m
mode set: ssb
qso: 2010-12-01 0005 dh1tw 15m ssb 59
qso: 2010-12-01 0007 w1aw 15m ssb 59
deleted qso: 2010-12-01 0007 w1aw 15m ssb
Log file transcribed by fastlog. https://github.com/cruvolo/fastlog
<ADIF_VER:5>2.1.4
<EOH>
<QSO_DATE:8>20101130 <TIME_ON:4>2347 <CALL:5>DF3CB <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2348 <CALL:6>DL6RAI <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2348 <CALL:5>DJ2MX <BAND:3>20M <MODE:2>CW <RST_SENT:3>599
<EOR>
<QSO_DATE:8>20101130 <TIME_ON:4>2351 <CALL:6>DL4MCF <BAND:3>20M <MODE:2>CW <RST_SENT:3>579 <RST_RCVD:3>559 <COMMENT:12>Good contact
<EOR>
<QSO_DATE:8>20101201 <TIME_ON:4>0005 <CALL:5>DH1TW <BAND:3>15M <MODE:3>SSB <RST_SENT:2>59
<EOR>
```

Interactive sessions can also work:

```
$ ./fastlog.pl > output.txt
date 2010-11-30
date set: 2010-11-30
band 20m
band set: 20m
mode cw
mode set: cw
1204 w1aw 579
qso: 2010-11-30 1204 w1aw 20m cw 579
$ cat output.txt
Log file transcribed by fastlog. https://github.com/cruvolo/fastlog
<ADIF_VER:5>2.1.4
<EOH>
<QSO_DATE:8>20101130 <TIME_ON:4>1204 <CALL:4>W1AW <BAND:3>20M <MODE:2>CW <RST_SENT:3>579
<EOR>
```

## known issues

* very little error checking / validity testing

