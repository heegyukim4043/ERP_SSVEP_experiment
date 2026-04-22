function Strooptest_scenario()
addpath('images');
% init_val
black_time = 0.1 ;% sec
cue_time = 0.2; % sec
task_time = 0.3; % sec

rest_min_time = 0.4; % sec
% rest_time_rand_range = 10;
% feedback_time = 3; %sec
num_trial = 10;
num_class = 4;

image_type = 'en'; %'kr'

% start - 10
% end - 20
% ---
% cue - 1
% task - 2
% task class - 21,22,23
% feedback - 3
% feedback class - 31,32,33
% rest - 4



class_list  = [] ;
for i = 1 : num_class
    class_list  = cat(2, class_list, ones(1,num_trial)*i);
end
suffle_list = rand(1,length(class_list));
[~,b]=sort(suffle_list);
class_list = class_list(b);


% textarea_fontspace = 50;
% true_pos = [1920/2 1080/2]; % x, y
% str_feedback = {'Coop','Defect'};

global t
t = tcpip('localhost',15361, 'NetworkRole', 'client');
fopen(t);
Openvibe_tcp(t, 10);
% 
% port = "COM13";  % Due 포트로 변경
% baud = 115200;
% 
% if exist('s','var'); clear s; end
% s = serialport(port, baud, "Timeout", 2);
% flush(s);

% writeline(s,"T1"); pause(3.5);
% writeline(s,"TRIGGER1");
% writeline(s,"T2"); pause(3.5);
% writeline(s,"T3"); pause(3.5);
% writeline(s,"TRIGGER3");

try
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebuglevel', 1);
    Screen('Preference', 'VBLTimestampingMode', 2);
    Screen('Preference', 'Enable3DGraphics', 1);
    Screen('Preference', 'OverrideMultimediaEngine',1);
    Screen('Preference', 'FrameRectCorrection', 1);
    Screen('Preference', 'TextRenderer', 1);
    Screen('Preference','TextEncodingLocale','UTF-8');
    
    %     [win, texture]=  Screen_init();
    
    myScreen = max(Screen('Screens'));
    [win,winRect] =   Screen(myScreen, 'OpenWindow');  % window size
    %     [win,winRect] =   Screen(myScreen,'OpenWindow',[],[0 0 1920 1080]);  % window size
    [width, height] = RectSize(winRect);
    Screen('FillRect',win,[0 0 0]);
    
    
    clear img
    [img] = imread('images/black.tif');
    texture_set{1} = Screen('MakeTexture', win, img);
    clear img
    [img] = imread('images/Cue.tif');
    texture_set{2} = Screen('MakeTexture',win,img);
    
    clear img
    [img] = imread(sprintf('images/%s/b_b_%s.tif',image_type,image_type));
    texture_set{3} = Screen('MakeTexture',win,img); 
    clear img
    [img] = imread(sprintf('images/%s/b_r_%s.tif',image_type,image_type));
    texture_set{4} = Screen('MakeTexture',win,img);
    clear img
    [img] = imread(sprintf('images/%s/r_b_%s.tif',image_type,image_type));
    texture_set{5} = Screen('MakeTexture',win,img);
    clear img
    [img] = imread(sprintf('images/%s/r_r_%s.tif',image_type,image_type));
    texture_set{6} = Screen('MakeTexture',win,img);
    
    
    
    %     Screen('DrawTexture',win,texture_set{4});
    
    
    %     Screen('DrawTexture',win,texture_set{1});
    %     Screen('DrawText', win,'TEST_string',...
    %                 true_pos(1)-950 +400*1,true_pos(2)-300, [255 255 255]);
    % %     Screen('DrawTexture',win,texture_set{2});
    %     Screen('Flip',win);
    
    WaitSecs(2);
    
    wait_key = 0; % for waiting..
    while(wait_key ~= 1)
        ifi = Screen('GetFlipInterval', win);
        
        
        % Preview texture briefly before flickering
        if wait_key == 2
            Screen('DrawTexture',win,texture_set{2});
            VBLTimestamp = Screen('Flip', win, ifi);
        elseif wait_key == 3
            Screen('Closeall');
        end
        wait_key = input('Start - 1, Draw visual stim - 2, Escape - 3 : ');
        
    end
    
    
    %% Start looping movie
    robot = java.awt.Robot();
    robot.mouseMove(2850, 670); % 위치 화면에 맞춰 조정
    robot.mousePress(java.awt.event.InputEvent.BUTTON1_MASK);
    robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_MASK);
    
    
    for trial_idx =1 : num_trial*num_class
        rest_time = rest_min_time; %%+ randi(rest_time_rand_range)/10;
%         rest_time = 
        % black screen
        tic;
        Screen('DrawTexture',win,texture_set{1});
        Screen('Flip', win);
        Openvibe_tcp(t, 1);
        while black_time >= toc
        end
        disp(sprintf('pre_cue:%04f',toc));
        save_time(trial_idx,1) = toc;
        
        % present cue
        tic;
        Screen('DrawTexture',win,texture_set{2});
        Screen('Flip', win);
        Openvibe_tcp(t, 2);
        while cue_time >= toc
        end
        disp(sprintf('Cue time:%04f',toc));
        save_time(trial_idx,2) = toc;
        
        
        % task present 
        tic;
        disp(sprintf('Class_type: %d',class_list(trial_idx))); 
        Screen('DrawTexture',win,texture_set{2+class_list(trial_idx)});
        Screen('Flip', win);
        Openvibe_tcp(t, 3);
        Openvibe_tcp(t, 30+class_list(trial_idx));
        while task_time >= toc
        end
        disp(sprintf('task time:%04f',toc));
        save_time(trial_idx,3) = toc;
        
        % rest present 
        tic;
%         disp(sprintf('Class_type: %d',class_list(trial_idx)));
        Screen('DrawTexture',win,texture_set{1});
        Screen('Flip', win);
        Openvibe_tcp(t, 5);
        while rest_time >= toc
        end
        disp(sprintf('rest time:%04f',toc));
        save_time(trial_idx,4) = toc;

    end
    
    newStr = erase(string(datetime),':');
    save(sprintf('save_timefile_%s.mat',newStr),'save_time');
    newStr = erase(string(datetime),':');
    save(sprintf('save_class_list_%s.mat',newStr),'class_list');

    Openvibe_tcp(t, 20);
    
    tic;
    while 10 >= toc
    end
    
    frame_duration = Screen('GetFlipInterval', win);
    Screen('CloseAll');
    Screen('Close');
    
catch
    Screen('CloseAll');
    Screen('Close');
    psychrethrow(psychlasterror);
    
    %     plot(timestamp,pulseAmp(1,:))
    %     xlim([0 2])
end


%%
% figure,
% plot(timestamp-timestamp(1),pulseAmp(1,:))
% ylim([0 1.1])
% xlim([0 2])
% title('10Hz', 'Fontsize',12);
% xlabel('time (sec)')
%
% figure,
% for i=1: length(timestamp)-1
%     interval_vec(i) = timestamp(i+1)-timestamp(i);
% end
% histogram(interval_vec,'BinWidth',0.1*10^-3);
%  title(sprintf('Avg: %0.4f std: %0.4f (ms)',mean(interval_vec)*1000, std(interval_vec)*1000));
