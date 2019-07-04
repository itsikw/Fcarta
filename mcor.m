function x = mcor(header,im,roisize)

%Figure
    h = figure('Name',header,'NumberTitle','off','MenuBar','none','ToolBar','none');
    image(im);
    axis off
    axis image
    imh = size(im,1);
    imw = size(im,2);

%Sample image
    [pr(1), pr(2)] = ginput(1);
    p = round(pr);

%Display and sample region-of-interest
    colstart = max(1,p(1)-roisize);
    colend = min(imw,p(1) + roisize);
    lstart = max(1,p(2)-roisize);
    lend = min(imh,p(2) + roisize);
    roiim = im(lstart:lend,colstart:colend,:);
    image(roiim);
    [sampler(1), sampler(2)] = ginput(1);
    sample = round(sampler);
    
%Compute sampled point image coordinates
    x = [colstart+sample(1) lstart+sample(2)];

%Exit
    close(h)
end