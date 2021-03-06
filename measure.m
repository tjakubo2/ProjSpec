function measure(setTime, channelCountNum)

global pomiar;
global measTime;
measTime = setTime;
pomiar = zeros(channelCountNum, measTime*100);

close all;
% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
%deviceDescription = 'DemoDevice,BID#0'; 
deviceDescription = 'PCI-1747U,BID#0'; 
startChannel = int32(0);
channelCount = int32(channelCountNum);

% Step 1: Create a 'InstantAiCtrl' for Instant AI function.
instantAiCtrl = Automation.BDaq.InstantAiCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    data = NET.createArray('System.Double', channelCount);
    
    %figure(1);
    %h = cell(1,channelCountNum);
    %ax = cell(1,channelCountNum);
%     for h_i = 1:channelCountNum
%         ax{h_i} = subplot(8,4,h_i);
%         h{h_i} = animatedline;
%         grid minor;
%     end
%     handles = struct('h', h, 'ax', ax);
    time = 0;

    
    % Step 3: Read samples and do post-process, we show data here.
    errorCode = Automation.BDaq.ErrorCode();
    while true
        t = timer('TimerFcn', {@TimerCallback, instantAiCtrl, startChannel, ...
            channelCount, data}, 'period', 0.01, 'executionmode', 'fixedrate');
    %drawTimer = timer('TimerFcn', {@DrawSignal, instantAiCtrl, startChannel, ...
        %channelCount, data}, 'period', 0.05, 'executionmode', 'fixedrate');
        %dataStruct = struct('h', handles, 'time', time, 'period', 1/2, 'count', 1);
        dataStruct = struct('time', time, 'period', 1/2, 'count', 1);
    %drawTimer.UserData = dataStruct;
        t.UserData = dataStruct;
        fprintf('\nPOMIAR: ')
        start(t);
        pause(setTime+0.2);
        fprintf('\nPAUZA:  ');
        for k=1:20
            pause(0.12);
            fprintf('#');
        end
        
        %while true
        %   if ~t.running
        %       pause(2);
        %       start(t);
        %   end
        %end
    end
    
    %start(t);
    %start(drawTimer);
    
    %pause(setTime*2);
    %stop(t);
    save('seria.mat', 'pomiar');
    %stop(drawTimer);
    %delete(drawTimer);
    delete(t);
catch e
    disp(e);
    % Something is wrong.
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' ... 
            + errorCode.ToString();
    else
        errStr = e.message;
    end
    disp(errStr); 
end

% Step 4: Close device and release any allocated resource.
instantAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

%global pomiar;
%pomiar = [];
function TimerCallback(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data)
newUserData = obj.UserData;
global measTime;
global pomiar;
if newUserData.count > measTime*100
    figure(2);
    suptitle('EMG');
    for h_i = 1:16
        subplot(4,4,h_i);
        plot(linspace(1, measTime, length(pomiar(h_i, :))), pomiar(h_i, :));
        grid minor; 
    end
    figure(3);
    suptitle('Tensometry');
    for h_i = 1:16
        subplot(4,4,h_i);
        plot(linspace(1, measTime, length(pomiar(h_i, :))), pomiar(h_i+16, :));
        grid minor; 
    end
    stop(obj);
    return;
end
%persistent pomiar;
%global pomiar;
%if isempty(pomiar)
%    pomiar = [];```
%end
errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
if BioFailed(errorCode)
    throw Exception();
end
if mod(newUserData.count, 10) == 0
   fprintf('#') 
end
seria = zeros(channelCount,1);
for j=0:channelCount-1
    seria(j+1) = data.Get(j);
    %fprintf('channel %d : %10f ', j, data.Get(j));
end
pomiar(:,newUserData.count) = seria;

newUserData.count = newUserData.count+1;
obj.UserData = newUserData;

end

function DrawSignal(obj, event, instantAiCtrl, startChannel, ...
    channelCount, data)
%errorCode = instantAiCtrl.Read(startChannel, channelCount, data); 
%if BioFailed(errorCode)
%    throw Exception();
%end
%pomiar = [pomiar; data.Get(1)];
global pomiar;
disp('UPDATE');
newUserData = obj.UserData;
ostPomiar = pomiar(:, newUserData.count);
newUserData.time = newUserData.time + newUserData.period;
for j=1:channelCount
    %axes(newUserData.h(j).ax);
    addpoints(newUserData.h(j).h, newUserData.time, ostPomiar(j));
    set(newUserData.h(j).ax, 'XLim', [newUserData.time-2 newUserData.time+1]);
    %xlim([newUserData.time-2 newUserData.time+1]);
    %fprintf('channel %d : %10f ', j, data.Get(j));
end
%axis([aa.time-2 aa.time+1 -5 5]);
obj.UserData = newUserData;
drawnow;
end