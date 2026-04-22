
figure_name = 'r_r_kr';

[X,map,alpha] = imread(sprintf('%s.png',figure_name));  % map이 비어있지 않으면 팔레트
if ~isempty(map), I = ind2rgb(X,map); else, I = X; end
imwrite(I, sprintf('%s.tif',figure_name), 'Compression','lzw');
