function [win]=Text_all_class_fixed(winWidth,winHeight,targetWidth,targetHeight,class_x,class_y,margin_x,margin_y,win)

class = class_x*class_y;

init_Height = 180;  % text area
init_Width = 60;    % interval width

len_W = winWidth - 2*init_Width;
len_H = winHeight - init_Height;

K_x = targetWidth*class_x + margin_x*(class_x-1); % RVS 부분의 총 길이
K_y = targetHeight*class_y + margin_y*(class_y-1);

init_x = (1800-K_x)/2 + 60;
init_y = (840-K_y)/2 + 180;

% targetWidth = targetWidth + 10;
% targetHeight = targetHeight +10;

for ind_Height = 1:class_y
    for ind_Width = 1: class_x
        temp_text=(ind_Height-1)*class_x +ind_Width;
        Screen('TextSize',win,50);
        if ( temp_text < 10)
            Screen('DrawText', win,num2str(temp_text),...
            targetWidth/2 + init_x + (targetWidth + margin_x)*(ind_Width -1)-15, ...
            targetHeight/2 +init_y + (targetHeight + margin_y)*(ind_Height -1)-15,...
            0);
        else
            Screen('DrawText', win,num2str(temp_text),...
            targetWidth/2 + init_x + (targetWidth + margin_x)*(ind_Width -1)-25, ...
            targetHeight/2 +init_y + (targetHeight + margin_y)*(ind_Height -1)-15,...
            0);
        end
    end
end


% cueTexture = targetMatrix;
end