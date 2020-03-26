function [tijd,x,y] = leesgazedataSMI(filenaam)

fid     = fopen(filenaam);
[fid,message] = fopen(filenaam);
if fid == -1
    error(message);
end

firstskip = 15;                           % to skip header unitl calibration info
for p=1:firstskip,
    fgetl(fid);
end

calibarea = fgetl(fid);
calibparams = strsplit(calibarea,'\t');
wcr = [str2num(calibparams{2}) str2num(calibparams{3})];

secondskip = 17;                           % to skip rest of the header
for p=1:secondskip,
    fgetl(fid);
end

dummy = textscan(fid,'%f%s%s%s%s%s%s%s%s%f%f%f%f%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s','delimiter','\t');

tijd            = dummy{:,1};
% time needs to be set to zero and is in microseconds!
tijd2           = tijd;
tijd2(2:end)    = (tijd2(2:end)- tijd2(1))/1000;
tijd2(1)        = 0;

tijd = tijd2;

% Convert values to double array
x           = cellfun(@str2num,dummy{:,4});
% correct for data that is beyond the world camera
x(x<0)      = NaN;
x(x>wcr(1)) = NaN;

% Convert values to double array
y           = cellfun(@str2num,dummy{:,5});
% correct for data that is beyond the world camera

y(y<0)      = NaN;
y(y>wcr(2)) = NaN;

disp(sprintf('%d lines of file %s processed',length(tijd),filenaam));