clear all
close all
clc
%set input data
Bitrate=4800; %bits per second
DataSize=9500; %Bytes
PollDataFrameSize=1024; %Bytes
LineDelay=2; %seconds
FrameCase=1; %1= 8bits per byte, 2=worst case of bit-stuffing
FailedFrame=4; %pick a frame that you want to see fail and recover from
%Go-Back-N Error correction

%LAPB specific HDLC dataframe fields
%Byte size
FlagSize=1;
AdressSize=1;
ControlSize=1;
ChecksumSize=2;
DataFieldSize=PollDataFrameSize-2*FlagSize-AdressSize-ControlSize-ChecksumSize;
%Assuming every frame has a dedicated start-stop flag. otherwise use 0.5
%and append one more flag to the first frame.
if DataFieldSize >= 1024
    ChecksumSize=4;
    DataFieldSize=DataFieldSize-2;
end
FinalDataFrameSize=PollDataFrameSize-DataFieldSize;
LastDataFieldSize=rem(DataSize,DataFieldSize);
LastPollDataFrameSize=PollDataFrameSize+LastDataFieldSize-DataFieldSize;

disp('Bytes | bits | worst-case bits')
FlagSize([2,3])=[FlagSize*8, FlagSize*8]
AdressSize([2,3])=[AdressSize*8, AdressSize*8]
ControlSize([2,3])=[ControlSize*8, ControlSize*8]%always 8 bits;recieve 111 is not less than send 111
ChecksumSize([2,3])=[ChecksumSize*8,ChecksumSize*9]
DataFieldSize([2,3])=[DataFieldSize*8,DataFieldSize*9]
PollDataFrameSize([2,3])=[PollDataFrameSize*8,2*FlagSize(3)+AdressSize(3)+ControlSize(3)+ChecksumSize(3)+DataFieldSize(3)]
FinalDataFrameSize([2,3])=[PollDataFrameSize(2)-DataFieldSize(2),PollDataFrameSize(3)-DataFieldSize(3)]
LastDataFieldSize([2,3])=[LastDataFieldSize*8,LastDataFieldSize*9]
LastPollDataFrameSize([2,3])=[LastPollDataFrameSize*8,LastPollDataFrameSize*8-LastDataFieldSize(2)+LastDataFieldSize(3)]

%We will take account for bit-stuffing when calculating values based on the bit-rate.
disp('Time (seconds); best | worst -case')
PollDataFrameTime([1,2])=[PollDataFrameSize(2)/Bitrate,PollDataFrameSize(3)/Bitrate]
LastPollDataFrameTime([1,2])=[LastPollDataFrameSize(2)/Bitrate,LastPollDataFrameSize(3)/Bitrate]
FinalDataFrameTime([1,2])=[FinalDataFrameSize(2)/Bitrate,FinalDataFrameSize(3)/Bitrate]

disp('Absolute values/count/mutliplier:')
DataFrameCount=ceil(DataSize/DataFieldSize(1))
WindowSize=1+ceil(FinalDataFrameTime(1)+2*LineDelay/PollDataFrameTime(2)) %hardcoded to worst case to cover all case
MaxWindowSize=bin2dec(repmat('1',[1,ControlSize(2)/2-1]))+1;%decimal of  a single row ([1,...]) of a binary's '1's
if WindowSize>MaxWindowSize
    WindowSize=MaxWindowSize;
    %WindowSize is limited by the control field size of HDLC-8 bit field
%only allows for 3 frame seqence bits or 8 frames
end

plot(0,0,'w');grid;
ylabel('0.5=DTE                  1.5=DCE')
xlabel(strcat('Failed frame number: ',num2str(FailedFrame)),'FontSize',12,'FontWeight','bold')
line(linspace(1,0),linspace(1.7,1.7),'Color','white')
text(0,0.67,'Frame number:','HorizontalAlignment','left','FontSize',10)
text(0,0.47,'T(s) sent:','HorizontalAlignment','left','FontSize',10)
text(0,0.4,'T(s) N/ACK recieved:','HorizontalAlignment','left','FontSize',10,'Color','blue')
text(0,1.57,'T(s) ACK/NACK sent:','HorizontalAlignment','left','FontSize',10)
text(0,1.47,strcat('S frame width (s): ',num2str(FinalDataFrameTime(FrameCase))),'HorizontalAlignment','left','FontSize',10)
safety=0;
framenum=0;
color='black';
errortime=-1; %-1 keeps error handling logic from tripping until detection and set
FFRlist=0;
IFFRslist=0;
LPFS=0;
LPFE=0;
IRO=0;
while framenum<DataFrameCount && safety<20
 framenum=framenum+1;
 safety=safety+1;
 if framenum == FailedFrame
  color='red';
 end
 if framenum < DataFrameCount 
  PFS=IRO+(framenum-1)*PollDataFrameSize(FrameCase+1)/Bitrate; %Poll frame start time
  PFE=IRO+framenum*PollDataFrameSize(FrameCase+1)/Bitrate; %Poll frame end time
  if (LineDelay*2>MaxWindowSize*PollDataFrameSize(FrameCase+1)/Bitrate) && (framenum > MaxWindowSize) && (FFR-PFS > PollDataFrameTime(FrameCase))
   PFS=IRO+(MaxWindowSize-1)*PollDataFrameSize(FrameCase+1)/Bitrate + (framenum-MaxWindowSize)*LineDelay;
   PFE=PFS+2*LineDelay;
   %when the return time is longer than the max window
   %transmission, frames after the max window limit are sent one round-trip apart.
  end
  FFS=PFE+LineDelay; %Final frame start time
  FFE=FFS+FinalDataFrameSize(FrameCase+1)/Bitrate; %Final frame end time
  FFR=FFE+LineDelay; %Final frame recieve time
  if framenum == FailedFrame
   errortime=FFR;
   text((FFE+FFR)/2,0.8,'S-Poll','HorizontalAlignment','left','FontSize',8,'color','red')
  else
   text((FFE+FFR)/2,0.8,'S-Final','HorizontalAlignment','left','FontSize',8,'color','blue')
  end
  FFRlist(end+1)=FFR; %append the recieve time value
  line(linspace(PFE,PFS),linspace(0.5,0.5),'Color',color)
  line(linspace(FFS,PFE),linspace(1.5,0.5),'Color',color)
  line(linspace(FFE,FFS),linspace(1.5,1.5))
  line(linspace(FFR,FFE),linspace(0.5,1.5))
  text(PFE,0.47,num2str(round(PFE,2)),'HorizontalAlignment','center','FontSize',8)
  text(FFR,0.4,num2str(round(FFR,2)),'HorizontalAlignment','left','FontSize',8,'color','blue')
  text(FFE,1.57,num2str(round(FFE,2)),'HorizontalAlignment','center','FontSize',8)
  text((PFE+FFS)/2,1.2,'I-Poll','HorizontalAlignment','left','FontSize',8)
  if framenum <= FailedFrame+WindowSize-1 && IRO == 0
   text((PFS+PFE)/2,0.6,int2str(framenum))
  elseif IRO == 0
   text((PFS+PFE)/2,0.6,int2str(framenum-WindowSize))
  else
   text((PFS+PFE)/2,0.6,int2str(framenum+FailedFrame-1))
  end
 end
 if framenum == DataFrameCount %draw the last frame as a LastPollDataFrameTime-offset of the previous one
  LPFS=PFE; %Last Poll frame start time
  LPFE=PFE+LastPollDataFrameTime(FrameCase); %Last Poll frame end time
  LFFS=FFS+LastPollDataFrameTime(FrameCase); %Last Final frame start time
  LFFE=FFE+LastPollDataFrameTime(FrameCase); %Last Final frame end time
  LFFR=FFR+LastPollDataFrameTime(FrameCase); %Last Final frame recieve time
  if (LineDelay*2>MaxWindowSize*PollDataFrameSize(FrameCase+1)/Bitrate) && (framenum > MaxWindowSize) && (FFR-PFS > PollDataFrameTime(FrameCase))
   LPFS=(MaxWindowSize-1)*PollDataFrameSize(FrameCase+1)/Bitrate + (framenum-MaxWindowSize)*LineDelay;%Last Poll frame start time
   LPFE=LPFS+2*LineDelay; %Last Poll frame end time
   LFFS=LPFE+LineDelay; %Last Final frame start time
   LFFE=LFFS+FinalDataFrameSize(FrameCase+1)/Bitrate; %Last Final frame end time
   LFFR=LFFE+LineDelay %Last Final frame recieve time
   %when the return time is longer than the max window
   %transmission, frames after the max window limit are sent one round-trip apart.
  end
  line(linspace(LPFE,LPFS),linspace(0.5,0.5),'Color','blue')
  line(linspace(LFFS,LPFE),linspace(1.5,0.5),'Color',color)
  line(linspace(LFFE,LFFS),linspace(1.5,1.5))
  line(linspace(LFFR,LFFE),linspace(0.5,1.5))
  text(LPFE,0.47,num2str(round(LPFE,2)),'HorizontalAlignment','center','FontSize',8)
  text(LFFR,0.4,num2str(round(LFFR,2)),'HorizontalAlignment','left','FontSize',8,'color','blue')
  text(LFFE,1.57,num2str(round(LFFE,2)),'HorizontalAlignment','left','FontSize',8)
  text((LPFE+LFFS)/2,1.2,'I-Poll','HorizontalAlignment','left','FontSize',8)
  if IRO ~= 0
   text((LFFE+LFFR)/2,0.8,'S-Final','HorizontalAlignment','left','FontSize',8,'color','blue') 
  end
  if framenum <= FailedFrame+WindowSize-1 && IRO == 0
   text((LPFS+LPFE)/2,0.6,int2str(framenum))
  elseif IRO == 0 
   text((LPFS+LPFE)/2,0.6,int2str(framenum-WindowSize))
  else
   text((LPFS+LPFE)/2,0.6,int2str(framenum+FailedFrame-1))
  end
  FFRlist(end+1)=LFFR;
  IFFRslist=FFRlist(FFRlist>LPFE); %post-LFPE Incoming Final frame recieve times
 end
  if (PFS < errortime && PFE > errortime)
   DataFrameCount=DataFrameCount+(framenum-FailedFrame)+1; 
   % +1 compensates for the frame duplication when executing Go-Back-N logic 
   color='green';
  else
   color='black';
  end
  if FailedFrame > DataFrameCount-length(IFFRslist) && framenum == DataFrameCount && IRO == 0
   %if FailedFrame is in the 'deadzone' of frames whose final is
   %recieved after the last polled dataframe, reset the counters and set the 
   %final error reception time as reference point (IRO) to run the full
   %loop again. the && statement prevents this section from running
   %again and lets only the normal drawing loop run.
   IRO=IFFRslist(FailedFrame-(DataFrameCount-length(IFFRslist))); %idle repeat offset
   if FailedFrame == DataFrameCount
    text((LFFE+LFFR)/2,0.8,'S-Poll','HorizontalAlignment','left','FontSize',8,'color','red')
    PFE=IRO
    FFS=PFE+LineDelay
    FFE=FFS+FinalDataFrameSize(FrameCase+1)/Bitrate
    FFR=FFE+LineDelay
   else
    text((LFFE+LFFR)/2,0.8,'S-Final','HorizontalAlignment','left','FontSize',8,'color','blue')
   end
   color='green';
   DataFrameCount=1+DataFrameCount-FailedFrame;
   framenum=0;
    %use IRO to shift the new window to the point of error detection, then
    %restart the loop to draw a new data transmission from that point    
  end
end
AverageDatarate=DataSize*8/(LFFR) %total payload data vs time until communication ends
ChannelUtilisationRatio=AverageDatarate/Bitrate %payload data rate vs hardware bitrate
title(strcat('Window size:',num2str(WindowSize),'  Channel utilisation ratio:',num2str(ChannelUtilisationRatio),'   Average Datarate: ',num2str(AverageDatarate),'bps'))


