
FROM:    The MOSIS System, >INTERNET:XMOSIS@CHEETA.ISI.EDU
TO:      Scott A Moore, 70461,3575
DATE:    10/11/91 at  0:50

SUBJECT: Topic: cksum1.pas

Sender: mosisout@vlsif.isi.edu
Received: from vlsif.isi.edu by ihc.compuserve.com (5.65/5.910516)
	id AA24840; Fri, 11 Oct 91 03:42:36 -0400
Posted-Date: 11 October 1991 0:25:38
Message-Id: <9110110731.AA29048@vlsif.isi.edu>
Received: by vlsif.isi.edu (5.61/5.61)
	id AA29048; Fri, 11 Oct 91 00:31:00 -0700
Date: 11 October 1991 0:25:38
From: The MOSIS System <XMOSIS@CHEETA.ISI.EDU> (send requests to MOSIS@MOSIS.EDU)
Subject: Topic: cksum1.pas
To: Scott A Moore <70461.3575@CompuServe.COM>

Your-message-sent: 11 Oct 91 03:07:44 EDT
Your-Message-ID: <911011070744_70461.3575_EHE41-1@CompuServe.COM>
MOSIS-Message-ID: imlr-00074138-91101100191400
MOSIS-Reply-Posted-for-Delivery: 11 October 1991 0:25:38


{ Calculates the CIF-Checksum.}
{ Prompts user for name of a CIF file. Writes the CIF-Checksum on output.}
{ Written in a portable pascal by Jeff Deifik 8/11/86 jdeifik@isi.edu }
{ Note: this program only accepts cif files named 'data', }
{ as standard pascal does not allow the user to determine the file name }
{ at run time. This is brain-damaged, but typical of pascal's lossage.}
{ It is suggested that the user modify this program to prompt for file name,}
{ or get the file name from the command line.}
{ Examples are provided for berkeley pascal, and vms pascal below.}

{ This program was written in very portable Pascal,}
{ and tested under VMS 4.2 & 5.0 and 4.3 bsd UNIX.}

{ To compile and run this CIF-CHECKSUM program:}

{ FOR VMS and pascal}
{ Using your favorite text editor, search for lines that contain
{ the word "VMS" and follow the directions.}
{ After saving the file, do the following:}
{ $ pascal check.pas}
{ $ link check.obj}
{ $ checksum :== $your-disk:[your-full-directory-path]check.exe}
{ $ checksum your-cif-file}

{ FOR UNIX and pascal}
{ Using your favorite text editor, search for lines that contain}
{ the word "BERKELEY" and follow the directions.}
{ After saving the file, do the following:}
{ % pc -O check.p -o check}
{ % check your-cif-file}

{ The pascal program has notes on what to do to make it run in three ways. }
{ There is a generic mode, that should run anywhere, but is not very }
{ friendly to use. There is a VMS mode for VMS, and a unix mode for unix. }



program checksum(input,output,data);

type	pstring	=	packed array [1..128] of char;

var	name	:	pstring;
	chksum	:	integer;	{ Checksum accumulates here.}
	nbyte	:	integer;	{ Byte count accumulates here.}
	sepflg	:	boolean;	{ Boolean for prevdataus separator.}
	c	:	char;	{ Gets a character from the file, or EOF.}
	data	:	text;

{ DELETE THIS LINE FOR VMS PASCAL 
procedure lib$get_foreign(%stdescr fred:pstring);extern;
DELETE THIS LINE FOR VMS PASCAL.}

procedure sum(ch:char);			{ Compute checksum 1 char at a time.}
begin
					{ Get rid of unwanted bits.}
    if (ch >= chr(128)) then ch := chr(ord(ch) - 128);

    if (ch > ' ') then			{ Is this a printing character? }
    begin
	chksum := chksum + ord(ch);
	nbyte := nbyte + 1;
	sepflg := false;
    end

    else if ((ch <> chr(0)) and (sepflg = false)) then
    begin
	chksum := chksum + 32;   	{ Process the first }
	nbyte := nbyte + 1;		{ separator in a row.}
	sepflg := true;
    end;
end;

begin					{ Main Program.}

    sepflg := true;			{ Set the separator flag.}
    chksum := 32;			{ Initial checksum value.}
    nbyte := 1;				{ Initial byte count.}

{ DELETE THIS LINE FOR BERKELEY PASCAL 
    if argc > 1 then
    begin
	argv(1,name);
	reset(data,name);
    end
    else
    begin
	write('Please specify file name on command line.');
	writeln;
    end;
DELETE THIS LINE FOR BERKELEY PASCAL.}

{ DELETE THIS LINE FOR VMS PASCAL
    lib$get_foreign(name);
    if name[1]=' ' then
    begin
	write('Please specify file name on command line.');
	writeln;
    end
    else
    begin
	open(data,name,old);
	reset(data);
    end;
DELETE THIS LINE FOR VMS PASCAL.}

{DELETE THESE THREE LINES IF USING VMS OR BERKELEY PASCAL.}
    reset(data);
{LAST LINE TO DELETE.}

    while not eof(data) do
    begin				{ Compute checksum.}

	while not eoln(data) do
	begin
	    read(data,c);
	    sum(c);
	end;
	readln(data);
	sum(' ');			{ Treat new-line as a space.}
    end;

    { Process the implied trailing separator.}

    if (sepflg = false) then
    begin
	chksum := chksum + 32;
	nbyte := nbyte + 1;
    end;

    write('CIF-checksum = ',chksum); writeln;
    write('Byte-count   = ',nbyte); writeln;

end.


