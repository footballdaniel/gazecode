function [tijd,x,y] = leesgazedataTobii(filenaam)

fid     = fopen(filenaam);
[fid,message] = fopen(filenaam);
if fid == -1
    error(message);
end

skip = 1;                           % om header over te slaan
for p=1:skip,
    fgetl(fid);
end

dummy = textscan(fid,'%s%s%s%f%f%f%f%f%f%f%s%f','delimiter','\t');
fclose(fid);

tijd    = dummy{:,4};
x       = dummy{:,7};
y       = dummy{:,8};


disp(sprintf('%d lines of file %s processed',length(tijd),filenaam));