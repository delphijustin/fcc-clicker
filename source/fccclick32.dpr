program fccclick32;
{$RESOURCE freeconferencecall.res}
{$APPTYPE CONSOLE}

uses
  SysUtils,
  windows,
  shellapi,
  graphics,
  classes,
  messages,
  math;

type
EMissingTime=class(Exception);
EBadRecCommand=class(exception);
EBadModeChar=class(exception)
public
constructor Create(C:char);
end;
ESource=class(Exception);
EAutoHotKey=class(exception)
public
constructor Create;
end;
TClickerCommand=function(command:string;parameters,switches:Tstringlist):longint;stdcall;
function GetProcessId(h:thandle):dword;stdcall;external kernel32;
function GetConsoleWindow:HWND;stdcall;external kernel32;
var ahk_exe:SHELLEXECUTEINFO;
parameters:tstringlist=nil;
commands:tstringlist=nil;
restart:Boolean=false;
ahkscript:tstringlist=nil;
stdout:THandle;
switches:tstringlist=nil;
cmdPIDs:tstringlist=nil;
thisexe:array[0..max_path]of char;
Duration:dword=60000;
maxtime:dword=((5*60)+45)*60000;
modes:string;
appkey:HKey=0;
Args:TStringlist=nil;
scriptsrunning:hkey=0;
hFCC:thandle;
otherProcess:THandle=0;
bLoaderPID:boolean=true;
memkey:HKEY=0;
bahkrunning:boolean=false;
R:TResourceStream=nil;
tid,ahkexit,clickercode,fcc_pid:DWORD;
clickerpid:DWORD=0;
command:TClickerCommand;
rId:array[0..32]of char='';
enumid:array[0..32]of char='';
timers:HKEY=0;
extracting:Boolean=false;
I:Integer;
results:longint;
timerid:dword=0;
otherscript,thisscript:dword;
const dw_delphiexe:DWord=maxword+1;
constructor ebadmodechar.Create;
begin
inherited Create(C+' is a not a valid mode symbol');
end;

procedure testMode(mode:char);
const ValidModes='!HLK';
begin
if(strscan(Validmodes,UpCase(Mode))<>nil)then exit;
raise ebadmodechar.Create(mode);
end;
function ahkHex(X:dword):string;
begin
result:=format('0x%x',[X]);
end;
procedure freeAndQuit(Code:DWORD=0);
var pidstr:array[0..15]of char;
ahkstatus:DWORD;
begin
if assigned(args)then args.Free;
if assigned(switches)then switches.Free;
if assigned(cmdpids)then cmdpids.Free;
if assigned(parameters)then parameters.Free;
if assigned(commands)then commands.Free;
if assigned(ahkscript)then ahkscript.Free;
if assigned(r)then r.Free;
if timers<>0then regclosekey(timers);
if appkey<>0then regclosekey(appkey);
if scriptsrunning<>0then begin getexitcodeprocess(ahk_exe.hProcess,ahkstatus);
if ahkstatus<>STILL_ACTIVE then begin regdeletevalue(scriptsrunning,strpcopy(
pidstr,ahkhex(getprocessid(ahk_exe.hProcess))));regdeletevalue(scriptsrunning,
strpcopy(pidstr,ahkhex(getcurrentprocessid)));end else terminateprocess(
ahk_exe.hProcess,0);
regclosekey(scriptsrunning);end;
if memkey<>0then regclosekey(memkey);
deletefile(ahk_exe.lpFile);

strdispose(ahk_exe.lpFile);
strdispose(ahk_exe.lpParameters);
exitprocess(code);
end;
constructor eautohotkey.Create;
begin
restart:=true;
if ahkexit=maxdword then begin inherited create('Error because of an exception');
exit;end;
inherited create(format('%s(0x%x)',[syserrormessage(ahkexit),ahkexit]));
end;
procedure quit(dwtype:dword);stdcall;
begin
freeandquit;
end;
function waitForFCC(timeout:dword):thandle;
var t,rs:DWord;
begin
result:=0;t:=0;
while(result=0)do begin rs:=4;regqueryvalueex(MemKey,'fcc_pid',nil,nil,@fcc_pid,
@rs);RESULT:=openprocess(PROCESS_TERMINATE OR PROCESS_QUERY_INFORMATION,false,
fcc_pid);sleep(1024);inc(t,1024);if t>timeout then exit;end;
end;

procedure badCommand;
begin
writeln(paramstr(1),' is not a valid command');
freeandquit(1);
end;
procedure help(command:string;parameters,switches:tstringlist);
var I:Integer;
topic:TStringlist;
begin
if(paramcount=0) or(paramcount<>2)then begin
Writeln('Usage: ',extractfilename(Paramstr(0)),' <command_name> [Parameters_and_switches]');
writeln('Commands:');
for i:=0to commands.Count-1do
writeln(commands.names[I],#32#32#32#32,commands.values[commands.names[I]]);
writeln;
writeln('Global Switches:');
writeln('/return=milliseconds   Don'#39't wait for autohotkey to finish. Just wait for some milliseconds then return. This doesn'#39't stop command, it makes it where this executable doesn'#39't wait for it');
writeln;
writeln('Type "',extractfilename(Paramstr(0)),' help <command_name>" for help on a certain command');
if paramcount=0then exit;
freeandquit(ord(Paramcount>1));
end;
r:=tresourcestream.create(hinstance,paramstr(2),'HELP');topic:=tstringlist.create;
topic.loadfromstream(R);r.free;writeln(topic.text);topic.free;r:=nil;freeandquit;
end;
procedure drawBitmap(hbmp:HBitmap);
var x,y:integer;
bitmap:tbitmap;
desktopRect:TRect;
desktopdc:Hdc;
begin
getclientrect(GetDesktopWindow,desktoprect);
desktopdc:=getdc(getdesktopwindow);
bitmap:=tbitmap.Create;
bitmap.Handle:=hbmp;
  // Calculate the center position
  X := (desktoprect.Right - Bitmap.Width) div 2;
  Y := (desktoprect.Bottom - Bitmap.Height) div 2;

StretchBlt(desktopdc,x,y,bitmap.Width,bitmap.Height,bitmap.Canvas.Handle,0,0,
bitmap.Width,bitmap.Height,SRCCOPY);
  bitmap.FreeImage;
  bitmap.Free;
 ReleaseDC(GetDesktopWindow,desktopdc);
end;

procedure timer(duration:dword);stdcall;
var oldtick,timeleft,rs:dword;
consolebuf:CONSOLE_SCREEN_BUFFER_INFO;
threadName:array[0..15]of char;
cursormoved,regSuccess:Boolean;
begin
cursormoved:=false;
while true do
begin
Oldtick:=0;rs:=4;
while oldtick=0do begin rs:=4;regsuccess:=(regqueryvalueex(timers,strpcopy(
threadname,ahkhex(getcurrentthreadid)),nil,nil,@oldtick,@rs)=error_success);
sleep(2048); end;
if not cursormoved then begin GetConsoleScreenBufferInfo(stdout,consolebuf);
cursormoved:=true;end else
SetConsoleCursorPosition(stdout,consolebuf.dwCursorPosition);
timeleft:=abs(gettickcount-oldtick);
if abs(duration-timeleft)<strtointdef(switches.Values['/alerttime'],30)*1024then
 drawbitmap(loadbitmap(hinstance,'FCCTIMER'));
writeln('TimeLeft: ',formatdatetime('hh:mm:ss',abs(duration-timeleft)*encodetime(
0,0,0,1)));
sleep(128);
end;
end;

function recordfor(command:string;parameters,switches:tstringlist):Longint;stdcall;
var dwPID:DWORD;
begin
result:=-1;
if parameters.Count=0then raise EMissingTime.Create('Need a duration');
r:=tresourcestream.Create(hinstance,'recordfor','AHK');
ahkscript.LoadFromStream(r);r.Free;r:=nil;
duration:=round(strtotimedef(parameters.DelimitedText,duration)/encodetime(0,0,0,1));
dwpid:=getcurrentprocessid;
regsetvalueex(MemKey,'RecordingPID',0,reg_dword,@dwpid,4);
CreateThread(Nil,0,@timer,pointer(duration),0,timerid);
end;

function startfcc(command:string;parameters,switches:tstringlist):Longint;stdcall;
begin
result:=-1;
r:=tresourcestream.Create(hinstance,'START','AHK');
ahkscript.LoadFromStream(r);r.Free;r:=nil;
createthread(nil,0,@timer,pointer(maxtime),0,timerid);
end;


function killfcc(command:string;parameters,switches:tstringlist):Longint;stdcall;
begin
hfcc:=waitforfcc(10240);
if not terminateprocess(hfcc,maxint)then raiselastoserror;
closehandle(hfcc);
result:=0;
end;
function enumScript(var regscript:dword;var index:Integer;pid:PChar):Boolean;
var rs,ns:dword;
begin
inc(index);
rs:=4;
ns:=33;
result:=(regenumvalue(scriptsrunning,Index,pid,ns,nil,nil,@regscript,@rs)=
error_success);
end;
function simpleAHKDefault(command:string;parameters,switches:tstringlist):Longint;stdcall;
begin
result:=0;
r:=tresourcestream.Create(hinstance,uppercase(paramstr(1)),'AHK');
ahkscript.LoadFromStream(r);r.Free;r:=nil;
end;
function simpleAHK(command:string;parameters,switches:tstringlist):Longint;stdcall;
begin
result:=-1;simpleahkdefault(command,parameters,switches);
end;
procedure reload;
begin
args:=tstringlist.Create;
args.Delimiter:=#32;
args.DelimitedText:=getcommandline;
args.Delete(0);
if restart then
args.Values['/error']:=inttostr(strtointdef(args.Values['/error'],0)+1);
shellexecute(getconsolewindow,nil,pchar(paramstr(0)),pchar(args.DelimitedText),
nil,sw_show);
end;

procedure install(command:string;parameters,switches:tstringlist);stdcall;
const errors:array[boolean]of string=('Failed]','OK]');
var exe,windir,dest:Array[0..max_path]of char;
begin
GetWindowsDirectory(windir,sizeof(windir));
getmodulefilename(0,exe,sizeof(exe));setlasterror(0);
writeln('fccclick32.exe[',errors[copyfile(exe,strcat(StrCopy(dest,windir),
'\fccclick32.exe'),false)]);if getlasterror>0then raiselastoserror;
writeln('delphian32.dll[',errors[copyfile('delphian32.dll',strcat(StrCopy(dest,
windir),'\delphian32.dll'),false)]);if getlasterror>0then raiselastoserror;
writeln(syserrormessage(0));
end;

procedure ifrun(command:string;parameters,switches:tstringlist);stdcall;
begin
hfcc:=waitforfcc(0);
if hfcc<>0then closehandle(hfcc);
freeandquit(ord(hfcc=0));
end;

procedure source(command:string;parameters,switches:tstringlist);stdcall;
begin
if not inrange(parameters.Count,1,2)then raise esource.Create(syserrormessage(
error_invalid_parameter));
r:=tresourcestream.Create(hinstance,uppercase(parameters[0]),'AHK');
ahkscript.LoadFromStream(r);r.free;r:=nil;extracting:=(Parameters.indexof(
'nofake')>0);if extracting then exit;write(ahkscript.text);freeandquit;
end;

begin
try
SetConsoleCtrlHandler(@quit,true);
stdout:=getstdhandle(std_output_handle);
getmodulefilename(hinstance,thisexe,sizeof(thisexe));
parameters:=tstringlist.Create;
switches:=tstringlist.Create;
parameters.Delimiter:=#32;
for I:=2to paramcount do if pos('/',paramstr(I))<>1then parameters.Add(Paramstr(
I))else switches.add(paramstr(i));
randomize;
maxtime:=round(strtotimedef(switches.values['/maxtime'],maxtime*encodetime(0,0,
0,1))/encodetime(0,0,0,1));
modes:=switches.values['/modes'];
for i:=1to length(modes)do testMode(modes[I]);
regcreatekeyex(hkey_current_user,'Software\Justin\FCCClicker',0,nil,
reg_option_non_volatile,key_all_access,nil,appkey,nil);
if regcreatekeyex(appkey,'Memory',0,nil,reg_option_volatile,key_all_access,nil,
memkey,nil)<>ERROR_SUCCESS then
raise exception.create('Failed to create volatile key');
regcreatekeyEx(Memkey,PChar('Scripts\'+Paramstr(1)),0,nil,reg_option_volatile,
key_all_access,nil,scriptsrunning,nil);
regcreatekeyex(memkey,'Timers',0,nil,reg_option_volatile,key_all_access,nil,
timers,nil);
commands:=tstringlist.Create;
ahkscript:=tstringlist.Create;
commands.Sorted:=true;
commands.AddObject('source=Writes the AutoHotKey source code for a certain command to the console',
TObject(@source));
commands.AddObject('ifrunning=returns with 0 for running and 1 if its not',
tobject(@ifrun));
commands.AddObject('close=Closes FCC process',tobject(@simpleahkdefault));
commands.AddObject('chat=Send a chat message',tobject(@simpleahkdefault));
commands.AddObject('kill=forces the fcc process to close',TObject(@killfcc));
commands.AddObject('install=Installs fcc clicker',TObject(@instaLL));
commands.AddObject('help=displays help',TObject(@Help));
commands.AddObject('start=host a FCC Meeting',TObject(@startfcc));
commands.AddObject('record=toggle record button',TObject(@simpleahk));
commands.AddObject('recordfor=record for a certain amount of time',TObject(@recordfor));
commands.AddObject('togglecam=Turns on or off webcam',TObject(@simpleahkdefault));
commands.AddObject('togglemic=turns on or off micrcophone',TObject(@simpleahkdefault));
commands.AddObject('togglenr=toggles noise reduction',TObject(@simpleahkdefault));
if paramcount=0then begin
help(emptystr,parameters,switches);
write('Press enter to quit...');readln;freeandquit(1);
end;
if commands.IndexOfName(paramstr(1))<0then badcommand;
@command:=pointer(commands.Objects[commands.IndexOfName(paramstr(1))]);
results:=command(paramstr(1),parameters,switches);
fillchar(ahk_exe,sizeof(ahk_exe),0);
ahk_exe.cbSize:=sizeof(ahk_exe);
ahk_exe.lpDirectory:=stralloc(max_path+1);
gettemppath(max_path,ahk_exe.lpDirectory);
copyfile('delphian32.dll',Pchar(strpas(Ahk_Exe.lpDirectory)+'\delphian32.dll'),false);
ahk_exe.fMask:=SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI or
SEE_MASK_NO_CONSOLE or SEE_MASK_DOENVSUBST;
ahk_exe.lpFile:=strfmt(stralloc(max_path+1),'%s\ahk.exe',[ahk_exe.lpDirectory]);
ahk_exe.lpParameters:=stralloc(MAX_PATH+1);
AHK_EXE.nShow:=SW_NORMAL;
ahkscript.Text:=stringreplace(ahkscript.Text,'@timerid',ahkhex(timerid),[
rfreplaceall]);ahkscript.Text:=stringreplace(ahkscript.Text,'@params',
parameters.DelimitedText,[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@whendone',ahkhex(strtointdef(
switches.Values['/return'],0)),[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@command',Paramstr(1),[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@modes',modes,[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@maxtime',ahkhex(maxtime),[
rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@duration',ahkhex(Duration),[
rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@args',stringreplace(
getcommandline,'"',emptystr,[rfreplaceall]),[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@delphipid',ahkhex(
getcurrentprocessid),[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@console',ahkhex(GetConsoleWindow),
[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@exename',thisexe,[rfreplaceall]);
ahkscript.Text:=stringreplace(ahkscript.Text,'@delphian32',format(
'%s\delphian32.dll',[extractfilepath(thisexe)]),[rfreplaceall]);
thisscript:=gettempfilename(ahk_exe.lpDirectory,pchar(ParamStr(1)),0,
ahk_exe.lpParameters);
ahkscript.Text:=stringreplace(ahkscript.Text,'@thisfile',ahk_exe.lpParameters,[
rfreplaceall]);
I:=-1;
regsetvalueex(scriptsrunning,strpcopy(rid,ahkhex(getcurrentprocessid)),0,reg_dword,@thisscript,4);
cmdpids:=tstringlist.Create;
try
r:=tresourcestream.CreateFromID(hinstance,32,'BIN');
r.SaveToFile(ahk_exe.lpFile);
except
bahkrunning:=true;
end;
regsetvalueex(Memkey,'RuntimeEXE',0,reg_sz,ahk_exe.lpFile,sizeof(Char)*(1+Strlen(
AHK_EXE.lpfile)));
while enumScript(otherscript,I,enumid)do
begin
if(comparetext(enumid,ahkhex(getcurrentProcessid))<>0)then
cmdpids.Add(enumid);
end;
ahkscript.Text:=stringreplace(ahkscript.Text,'@cmdProcesses',cmdpids.CommaText,
[rfreplaceall]);

if extracting then begin write(ahkscript.text);freeandquit;end;
ahkscript.SaveToFile(ahk_exe.lpParameters);
if strtointdef(parameters.Values['/error'],0)>0then writeln('Clicker has crashed ',
switches.values['/error'],' in a row');
writeln('[',datetimetostr(now),'] Command "',paramstr(1),'" Started');
if not shellexecuteex(@ahk_exe)then raiselastoserror;
regsetvalueex(scriptsrunning,strpcopy(rid,ahkhex(GetProcessId(ahk_exe.hProcess))),
0,reg_dword,@dw_delphiexe,4);
Sleep(4096);
waitforsingleobject(ahk_exe.hProcess,strtoint64def(switches.Values['/return'],
infinite));
getexitcodeprocess(ahk_exe.hProcess,ahkexit);
writeln('[',datetimetostr(now),'] Finished(',ahkexit,')');
if ahkexit>0then raise eautohotkey.Create;
freeandquit(ahkexit);
except on e:exception do
writeln(e.classname,': ',e.Message);
end;
(*if restart then writeln('Restarting in 5 seconds...');
sleep(5120);
if not restart then freeandquit(maxlong);
reload;
*)
freeandquit(maxdword);
end.
