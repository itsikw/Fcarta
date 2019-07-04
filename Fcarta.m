%This script registers photos sequence
%(c) Yitzhak Weissman 2019
%This software is publicly shared.
%Use under your own responsibility. No guarantee is given concerning the
%software results.
%ver 4: removed reference measurement


%% Init
clear all
close all
pkg load image;

%Workfolder
curdir = dir;
curfolder = curdir(1).folder;
if exist('appdata\workfolder.mat')==2
    load ('appdata\workfolder.mat', 'workfolder');
    workfolder = uigetdir(workfolder, 'Choose work folder');
else
    workfolder = uigetdir(curfolder, 'Choose work folder');
end
if ischar(workfolder)
    save('appdata\workfolder.mat','workfolder');
end

%Photos
PhotoPath = uigetdir(workfolder,'Choose photos sequence folder:');
PhotoFolderContent = dir(PhotoPath);
nPhot = size(PhotoFolderContent,1) - 2;

%Measurements
ans = questdlg('Open existing measurements file?');
if ans(1) == 'Y'
    [DataFileName, DataPath] = uigetfile([workfolder '*.mat'],'Open measurements file:');
    load ([DataPath DataFileName]);
else
    curfolder = cd(workfolder);
    [DataFileName, DataPath] = uiputfile('*.mat','Choose file to save measurements:');
    cd(curfolder);
end

%Config
if exist('appdata\config.mat')==2
    load ('appdata\config.mat');    
    defans = {num2str(roisize), num2str(RefFrameWidth), num2str(RefFrameHeight)};
else
    defans = {'50','1908','2671'};
end
prompt = {'region of interest size', 'Ref frame width (pixels)', 'Ref frame height (pixels)'};
rowscols = [1,10; 1,10; 1,10];
ans = inputdlg (prompt, 'Enter parameters', ...
                 rowscols, defans); 
% roisize = 50;
% RefFrameWidth = 1916;
% RefFrameHeight = 2672;
roisize = str2num(ans{1});
RefFrameWidth = str2num(ans{2});
RefFrameHeight = str2num(ans{3});
save('appdata/config.mat','roisize','RefFrameWidth','RefFrameHeight');

%Reference control points
tl = [0 0];
tr = tl + [RefFrameWidth 0];
bl = tl + [0 RefFrameHeight];
br = tl + [RefFrameWidth RefFrameHeight]; 
refpoints = [tl; tr; bl; br];

%% Get measurements data

if ~exist('a')
    ipict = 1;
else
    ipict = size(a,2) + 1;
    disp(['Measured points of ' num2str(size(a,2)) ' photos loaded.']); 
end
if ipict <= nPhot
    disp('Start measuring points. To abort, close figure window.')
end
imeasure = ipict;
%for i = ipict:nPhot %Measure points
while (imeasure <= nPhot)
  PhotoName = PhotoFolderContent(imeasure+2).name;
  im = imread([PhotoPath PhotoName]);
  tl = mcor([PhotoName ' top left'],im,roisize);
  tr = mcor([PhotoName ' top right'],im,roisize);
  bl = mcor([PhotoName ' bottom left'],im,roisize);
  br = mcor([PhotoName ' bottom right'],im,roisize);
  a(imeasure).points = [tl; tr; bl; br];  
  ans = questdlg(['Save measure points for ' PhotoName '?']);
  if ans(1) == 'Y'
    %imeasure = imeasure + 1;
    imeasure++;
    save([DataPath DataFileName],'refpoints','a');
    disp([PhotoName ' data points saved.']);
  else
    disp(['Repeating measurement of ' PhotoName]);
  end
endwhile

%% Rectify all photos
for i = 1:nPhot
    PhotoName = PhotoFolderContent(i+2).name;
    im = imread([PhotoPath PhotoName]);
    disp(['Processing photo ' PhotoName]);            
    mytform = cp2tform(a(i).points, refpoints, 'projective');
    [recim(i).im,x(i).data,y(i).data] = imtransform(im, mytform);
end

%% Compute canvas size
colstart = x(1).data(1);
colend = x(1).data(2);
lstart = y(1).data(1);
lend = y(1).data(2);
for i = 2:nPhot
    if x(i).data(1)<colstart; colstart = x(i).data(1); end
    if x(i).data(2)>colend; colend = x(i).data(2); end
    if y(i).data(1)<lstart; lstart = y(i).data(1); end
    if y(i).data(2)>lend; lend = y(i).data(2); end
end
canvash = ceil(lend-lstart)+10;
canvasw = ceil(colend-colstart)+10;

%% Create aligned pictures
reg = zeros(canvash,canvasw,3,nPhot,'uint8');
for i = 1:nPhot
    picth = size(recim(i).im,1);
    pictw = size(recim(i).im,2);
    pictlstart(i) = ceil(y(i).data(1)-lstart+1);
    pictcolstart(i) = ceil(x(i).data(1)-colstart+1);
    reg(pictlstart(i):pictlstart(i)+picth-1, ...
        pictcolstart(i):pictcolstart(i)+pictw-1,:,i) ...
        = recim(i).im;
end

%% Save
RegFolder = uigetdir(workfolder,'Choose registered images folder');
for i = 1:nPhot
    PhotoName = PhotoFolderContent(i+2).name;
    imwrite(reg(:,:,:,i),[RegFolder PhotoName]);
end
