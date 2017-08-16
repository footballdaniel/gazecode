function gazecode()

% GazeCode
% ========
%
% This open-source collection of m-files (and its demo files) have been
% developed and recorded by J.S. Benjamins, R.S. Hessels and I.T.C. Hooge. 
% When using this toolbox for coding mobile eye-tracking data, please refer 
% to the correct mansucript listed on GitHub. 
%
% This software loads a movie visualising raw eye-tracking data and
% the accompanying exported data from a mobile eye-tracker (currently sup-
% porting Pupil Labs and Tobii Pro Glasses eye-trackers), runs a fixation
% detection algorithm on the data (currently Hooge and Camps 2013) and
% consequently only displays the video frames belonging to the detected
% fixations which can be browsed through and coded by using buttons, or key-
% board keys Z and X, and assigned a category code from 1-9 by using buttons, 
% or keyboard (numpad) keys 1-9. Keyboard key 0 resets all categories. These
% categories will be set by selecting  a directory of non-transparent PNG 
% files of 100 x 100 pixels.
%
% Please contact main developer J.S. Benjamins through GitHub when further 
% information is needed.

%% start fresh
clear all; close all; clc;

%% ========================================================================
% BIG NOTE: every variable that is needed somewhere in this code is stored
% in a structure array called gv that is added to the main window with the
% handle hm as userdata. When changing or adding variables in this struct
% it is thus needed to fetch using gv = get(hm, 'userdata') an update using
% use set(hm,'userdata',gv);
%% ========================================================================

% global gv;
gv.curframe     = 1;
gv.minframe     = 1;
gv.maxframe     = 1;
gv.curfix       = 1;
gv.maxfix       = 1;
skipdataload    = false;

% knoppen
gv.fwdbut  = 'x'; % move forward (next fixation)
gv.bckbut  = 'z'; % move backward (previous fixation)
gv.cat1but = {'1','numpad1'};
gv.cat2but = {'2','numpad2'};
gv.cat3but = {'3','numpad3'};
gv.cat4but = {'4','numpad4'};
gv.cat5but = {'5','numpad5'};
gv.cat6but = {'6','numpad6'};
gv.cat7but = {'7','numpad7'};
gv.cat8but = {'8','numpad8'};
gv.cat9but = {'9','numpad9'};
gv.cat0but = {'0','numpad0'};

%% directories en settings
gv.foldnaam     = 0;
gv.catfoldnaam  = 0;
gv.fs           = filesep;
gv.codedir      = pwd;
addpath(gv.codedir);

gv.rootdir      = pwd;

cd ..;

gv.resdir       = [cd gv.fs 'results'];
cd(gv.resdir);

cd ..;

gv.catdir       = [cd gv.fs 'categories'];
cd(gv.catdir);

cd ..;

gv.appdir       = [cd gv.fs 'application'];
cd(gv.appdir);

cd ..;

gv.datadir      = [cd gv.fs 'data'];
cd(gv.datadir);

gv.splashh = gazesplash([gv.appdir gv.fs 'splash.png']);
pause(1);
close(gv.splashh);

%% Select type of data you want to code (currently a version for Pupil Labs and Tobii Pro Glasses are implemented

% this is now a question dialog, but needs to be changed to a dropdown for
% more options. Question dialog allows for only three options
gv.datatype = questdlg(['What type of of mobile eye-tracking data do you want to code?'],'Data type?','Pupil Labs','Tobii Pro Glasses','Pupil Labs');

if strcmp(gv.datatype,'Tobii Pro Glasses')
    help dispTobiiInstructions;
    dispTobiiInstructions;
    clc;
    TobiiOK = questdlg(['Do you have a video export from Tobii in MP4 format and a data file in TXT format?'],'Do you have the right Tobii files?','Yes, continue','No & quit','Yes, continue');
    if strcmp(TobiiOK,'No & quit')
        disp('GazeCode quit, since you indicated not having the correct Tobii files.')
        return
    end
end

% set camera settings of eye-tracker data
switch gv.datatype
    case 'Pupil Labs'
        gv.wcr = [1280 720]; % world cam resolution
        gv.ecr = [640 480]; % eye cam resolution
    case 'Tobii Pro Glasses'
        gv.wcr = [1920 1080]; % world cam resolution
        gv.ecr = [640 480]; % eye cam resolution (assumption, not known ATM)
end

%% load data folder
while gv.foldnaam == 0
    gv.foldnaam    = uigetdir(gv.datadir,'Select data directory to code');
end

while gv.catfoldnaam == 0
    gv.catfoldnaam    = uigetdir(gv.catdir,'Select directory of categories');
end

filmnaam    = strsplit(gv.foldnaam,gv.fs);
gv.filmnaam    = filmnaam{end};

% check if results dir already exists (in that case, load previous or start
% over), otherwise create dir.
resdir = [gv.resdir gv.fs gv.filmnaam];
if exist([resdir gv.fs gv.filmnaam '.mat']) > 0
    oudofnieuw = questdlg(['There already is a results directory with a file for ',gv.filmnaam,'. Do you want to load previous results or start over? Starting over will overwrite previous results.'],'Folder already labeled?','Load previous','Start over','Load previous');
    if strcmp(oudofnieuw,'Load previous')
        % IMPORANT NOTE FOR TESTING! This reloads gv! Use start over when
        % making changes to this file.
        load([resdir gv.fs gv.filmnaam '.mat']);
        skipdataload = true;
    else
        rmdir(resdir,'s');
        mkdir(resdir);
    end
elseif exist(resdir) == 0
    mkdir(resdir);
else
    % do nothing
end

%% init main screen, don't change this section if you're not sure what you are doing
hm          = figure(1);
set(hm,'Name','GazeCode','NumberTitle','off');
hmmar       = [150 100];

set(hm, 'Units', 'pixels');
ws          = get(0,'ScreenSize');

% set figure full screen, position is bottom left width height!;
set(hm,'Position',[ws(1) + hmmar(1), ws(2) + hmmar(2), ws(3)-2*hmmar(1), ws(4)-2*hmmar(2)]);
% this is the first time gv is set to hm!
set(hm,'windowkeypressfcn',@verwerkknop,'closerequestfcn',@sluitaf,'userdata',gv);

% get coordinates main screen
hmpos       = get(hm,'Position');

hmxc        = hmpos(3)/2;
hmyc        = hmpos(4)/2;

hmxmax      = hmpos(3);
hmymax      = hmpos(4);

% disable all button etc.
set(hm,'MenuBar','none');
set(hm,'DockControls','off');
set(hm,'Resize','off');


% main menu 1
mm1         = uimenu(hm,'Label','Menu');
% sub menu of main menu 1
sm0         = uimenu(mm1,'Label','Save to text','CallBack',@savetotext);
sm1         = uimenu(mm1,'Label','About GazeCode','CallBack','uiwait(msgbox(''This is version 1.0.1'',''About FixLabel''))');

%% left panel (Child 2 of hm), don't change this section if you're not sure what you are doing 
lp          = uipanel(hm,'Title','Fix Playback/Lookup','Units','pixels','FontSize',16,'BackgroundColor',[0.8 0.8 0.8]);
lpmar       = [50 20];

set(lp,'Position',[1+lpmar(1) 1+lpmar(2) (hmxmax/2)-2*lpmar(1) hmymax-2*lpmar(2)]);
lpsize = get(lp,'Position');
lpsize = lpsize(3:end);


knopsize = [100 100];
knopmar = [20 10];

fwknop = uicontrol(lp,'Style','pushbutton','string','>>','callback',@playforward,'userdata',gv.fwdbut);
set(fwknop,'position',[lpsize(1)-knopsize(1)-knopmar(1) knopmar(2) knopsize]);
% set(fwknop,'backgroundcolor',[1 0.5 0]);
set(fwknop,'fontsize',20);

bkknop = uicontrol(lp,'Style','pushbutton','string','<<','callback',@playback,'userdata',gv.bckbut);
set(bkknop,'position',[knopmar knopsize]);
% set(bkknop,'backgroundcolor',[1 0.5 0]);
set(bkknop,'fontsize',20);

%% right panel (child 1 of hm), don't change this section if you're not sure what you are doing
rp          = uipanel('Title','Categories','Units','pixels','FontSize',16,'BackgroundColor',[0.8 0.8 0.8]);
rpmar       = [50 20];

set(rp,'Position',[hmxc+rpmar(1) 1+rpmar(2) (hmxmax/2)-2*rpmar(1) hmymax-2*rpmar(2)]);
rpsize      = get(rp,'Position');
rpsize      = rpsize(3:end);

% right panel buttons
knopsize    = [150 150];
knopmar     = [20];

% make grid
widthgrid   = knopsize(1)*3+2*knopmar;
heightgrid  = knopsize(2)*3+2*knopmar;
xstartgrid    = floor((rpsize(1) - widthgrid)/2);
ystartgrid  = rpsize(2) - heightgrid - knopmar;

opzij       = knopmar+knopsize(1);
omhoog      = knopmar+knopsize(2);
gridpos     = [...
    xstartgrid, ystartgrid, knopsize;...
    xstartgrid+opzij, ystartgrid, knopsize;...
    xstartgrid+2*opzij, ystartgrid, knopsize;...
    
    xstartgrid ystartgrid+omhoog knopsize;...
    xstartgrid+opzij ystartgrid+omhoog knopsize;...
    xstartgrid+2*opzij ystartgrid+omhoog knopsize;...
    
    xstartgrid ystartgrid+2*omhoog knopsize;...
    xstartgrid+opzij ystartgrid+2*omhoog knopsize;...
    xstartgrid+2*opzij ystartgrid+2*omhoog knopsize;...
    ];

gv.knoppen = [];

for p = 1:size(gridpos,1)
    gv.knoppen(p) = uicontrol(rp,'Style','pushbutton','HorizontalAlignment','left','string','','callback',@labelfix,'userdata',gv);
    set(gv.knoppen(p),'position',gridpos(p,:));
    set(gv.knoppen(p),'backgroundcolor',[1 1 1]);
    set(gv.knoppen(p),'fontsize',20);
    set(gv.knoppen(p),'userdata',p);
    imgData = imread([gv.catfoldnaam gv.fs num2str(p) '.png']);
    imgData = imgData./maxall(imgData);
    set(gv.knoppen(p),'CData',imgData);
end
set(hm,'userdata',gv);

%% position axes of right panel to upper part of right panel. Don't change this section if you're not sure what you are doing
rpax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', rp,'visible','off');
set(rpax,'Units','pixels');
rpaxpos = get(rpax,'position');

tempx = rpaxpos(1);
tempy = rpaxpos(2);
tempw = rpaxpos(3);
temph = rpaxpos(4);

tempw = tempw - mod(tempw,16);
temph = (tempw/16) * 9;

tempx = floor((rpaxpos(3) - tempw)/2);
tempy = rpaxpos(4)-temph;

set(rpax,'Position',[tempx tempy tempw temph],'visible','off');
gv.rpaxpos = get(rpax,'position');


%% position axes of left panel to upper part of left panel. Don't change this section if you're not sure what you are doing
lpax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', lp,'visible','off');
set(lpax,'Units','pixels');
lpaxpos = get(lpax,'position');

tempx = lpaxpos(1);
tempy = lpaxpos(2);
tempw = lpaxpos(3);
temph = lpaxpos(4);

tempw = tempw - mod(tempw,16);
temph = (tempw/16) * 9;

tempx = floor((lpaxpos(3) - tempw)/2);
tempy = lpaxpos(4)-temph;

set(lpax,'Position',[tempx tempy tempw temph],'visible','on');
gv.lpaxpos = get(lpax,'position');

%% read video of visualisation, here cases can be added for other mobile eye trackers

% the Pupil Labs version expects the data to be in a specific folder that
% is default when exporting visualisations in Pupil Labs with a default
% name of the file, Tobii Pro Glasses does not, so select it.
switch gv.datatype
    case 'Pupil Labs'
        waarisdefilmdir = [gv.foldnaam gv.fs 'exports'];
        
        [hoeveelfilms, nhoeveelfilms] = folderfromfolder(waarisdefilmdir);
        
        if nhoeveelfilms > 1
            % to be done still, select which visualisation movie to use if multiple
            % exist
        end
        gv.vidObj  = VideoReader([gv.foldnaam gv.fs 'exports' gv.fs hoeveelfilms.name gv.fs 'world_viz.mp4']);
    case 'Tobii Pro Glasses'
        [videofile,videopath] = uigetfile('.mp4','Select video file');
        gv.vidObj = VideoReader([videopath gv.fs videofile]);
end

gv.fr       = get(gv.vidObj,'FrameRate');
frdur       = 1000/gv.fr;
nf          = get(gv.vidObj,'NumberOfFrames');
gv.maxframe = nf;
gv.centerx  = gv.vidObj.Width/2;
gv.centery  = gv.vidObj.Height/2;
set(hm,'userdata',gv);

%% fixation detection using data
% read data and determine fixations, here cases can be added for other 
% mobile eye trackers, as well as changing the fixation detection algorithm 
% by altering the function that now runs on line 386.
if ~skipdataload
    % to be done still, select data file from results directory if you
    % want to skip data loading
    
    gv = get(hm,'userdata');
    disp('Determining fixations...');
    switch gv.datatype
        case 'Pupil Labs'
            tempfold = folderfromfolder([gv.foldnaam gv.fs 'exports']);
            % if there are more than one exports, it just takes the first!
            tempfold = tempfold(1).name;
            % note the typo! Pupila Labs currently exports postions not
            % positions!
            filenaam = [gv.foldnaam gv.fs 'exports' gv.fs tempfold gv.fs 'gaze_postions.csv'];
            
            % this file reads the exported data file from Pupil Labs and gets time
            % stamp and x and y coordinates
            [gv.datt, gv.datx, gv.daty] = leesgazedata(filenaam);
            % recalculate absolute timestamps to time from onset (0 ms)
            gv.datt = double(gv.datt);
            gv.datt2 = gv.datt;
            gv.datt2(1) = 0;
            for p = 2:length(gv.datt)
                gv.datt2(p) = gv.datt(p) - gv.datt(p-1);
                gv.datt2(p) = gv.datt2(p) + gv.datt2(p-1);
            end
            gv.datt2 = gv.datt2*1000;
            gv.datt = gv.datt2;
            
            gv.datx(gv.datx > 1) = NaN;
            gv.datx(gv.datx < 0) = NaN;
            
            gv.daty(gv.daty > 1) = NaN;
            gv.daty(gv.daty < 0) = NaN;
            
            gv.datx = gv.datx * gv.wcr(1) - gv.wcr(1)/2;
            gv.daty = gv.daty * gv.wcr(2) - gv.wcr(2)/2;
            
        case 'Tobii Pro Glasses'
            
            [filenaam, filepad] = uigetfile('.txt','Select data file with fixations');
            
            [gv.datt, gv.datx, gv.daty] = leesgazedataTobii([filepad gv.fs filenaam]);
            
            gv.datx = gv.datx * gv.wcr(1) - gv.wcr(1)/2;
            gv.daty = gv.daty * gv.wcr(2) - gv.wcr(2)/2;
            
        otherwise
            disp('Unknown data type, crashing in 3,2,1,...');
    end
    % determine start and end times of each fixation in one vector (odd
    % number start times of fixations even number stop times)
    
    % The line below determines fixations start and stop times since the
    % beginning of the recording. For this detection of fixations the algo-
    % rithm of Hooge and Camps (2013), but this can be replaced by your own
    % favourite or perhaps more suitable fixation detectioon algorithm.
    % Important is that this algorithm returns a vector that has fixation
    % start times at the odd and fixation end times at the even positions
    % of it.
    gv.fmark = fixdetect(gv.datx,gv.daty,gv.datt,gv);
    
    fixB = gv.fmark(1:2:end);
    fixE = gv.fmark(2:2:end);
    fixD = fixE- fixB;
    
    [temptijd,idxtB,idxfixB] = intersect(gv.datt,fixB);
    xstart = gv.datx(idxtB);
    ystart = gv.daty(idxtB);
    
    [temptijd,idxtE,idxfixE] = intersect(gv.datt,fixE);
    xend = gv.datx(idxtE);
    yend = gv.daty(idxtE);
    
    for p = 1:length(idxtB)
        xmean(p,1) = mean(gv.datx(idxtB(p):idxtE(p)));
        ymean(p,1) = mean(gv.daty(idxtB(p):idxtE(p)));
        
        xsd(p,1) = std(gv.datx(idxtB(p):idxtE(p)));
        ysd(p,1) = std(gv.daty(idxtB(p):idxtE(p)));
    end
    
    fixnr = [1:length(fixB)]';
    fixlabel    = zeros(size(fixnr));
    
    gv.data = [fixnr, fixB, fixE, fixD, xstart, ystart, xend, yend, xmean, xsd, ymean, ysd, fixlabel];
    gv.maxfix   = max(fixnr);
    
    set(hm,'userdata',gv);
    disp('... done');
    
    % determine begin and end frame beloning to fixations start and end
    % times
    gv.bfr     = floor(fixB/frdur);
    gv.efr     = ceil(fixE/frdur);
    
    % determine the frame between beginning and end frame for a fixations,
    % this one will be displayed
    gv.mfr = floor((gv.bfr+gv.efr)/2);
    if gv.mfr(end) > gv.maxframe
        gv.mfr(end) = gv.maxframe;
    end
    
    gv.fixxpos = (gv.centerx + xmean);
    gv.fixypos = (gv.centery - ymean);
    
    gv.fixxposB = gv.centerx + xstart;
    gv.fixyposB = gv.centery + ystart;
    
    gv.fixxposE = gv.centerx + xend;
    gv.fixyposE = gv.centery + yend;
    
    
    gv.bfr(gv.bfr<1) = 1;
    gv.bfr(gv.bfr>nf) = nf;
    
    gv.efr(gv.efr<1) = 1;
    gv.efr(gv.efr>nf) = nf;
    set(hm,'userdata',gv);
end

%% start to show the first frame or when reloading the frame last coded.
showmainfr(hm,gv);

end

% function to attribute a category code to the fixation, this is a function 
% of the buttons in the right panel
function labelfix(src,evt)
% if zero is pressed a code is reset
if ~strcmp(evt.Character,'0');
    categorie = get(src,'userdata');
    rp = get(src,'parent');
    hm = get(rp,'parent');
    gv = get(hm,'userdata');
else
    hm = src;
    categorie = 0;
    gv = get(hm,'userdata');
end
data = gv.data;
data(gv.curfix,end) = categorie;
gv.data = data;
setlabel(gv);

set(hm,'userdata',gv);
end

% function to show the current frame and fixation being labeled
function showmainfr(hm,gv)
plaat = read(gv.vidObj,gv.mfr(gv.curfix));
imagesc(plaat);
gv.frameas = gca;
axis off;
axis equal;
% clc;
disp(['Current fixation: ', num2str(gv.curfix),'/',num2str(gv.maxfix)]);

hold(gv.frameas,'off');
setlabel(gv);

if isempty(gv.data(:,end)==0)
    msgbox('All fixations of this directory seem to be labeled','Warning','warn');
end

set(hm,'userdata',gv);
end

function setlabel(gv)
if gv.data(gv.curfix,end) > 0
    for p = 1:size(gv.knoppen,2)
        if p == gv.data(gv.curfix,end)
            set(gv.knoppen(p),'backgroundcolor',[1 0.5 0]);
        else
            set(gv.knoppen(p),'backgroundcolor',[1 1 1]);
        end
    end
else
    for p = 1:size(gv.knoppen,2)
        set(gv.knoppen(p),'backgroundcolor',[1 1 1]);
    end
end
end

% function to move one fixation further, function of button in left panel
function playforward(src,evt)
lp = get(src,'parent');
hm = get(lp,'parent');
gv = get(hm,'userdata');

if gv.curfix < gv.maxfix
    gv.curfix = gv.curfix + 1;
    showmainfr(hm,gv);
else
    msgbox('Last fixation reached','Warning','warn');
end
set(hm,'userdata',gv);
end

% function move one fixation back, function of button in left panel
function playback(src,evt)
lp = get(src,'parent');
hm = get(lp,'parent');
gv = get(hm,'userdata');

if gv.curfix > 1
    gv.curfix = gv.curfix - 1;
    showmainfr(hm,gv);
else
    h = msgbox('First fixation reached','Warning','warn');
end
set(hm,'userdata',gv);
end

% function to handle keypresses as shortcuts, function of main screen
function verwerkknop(src,evt)
gv = get(src,'userdata');
tsrc = get(src,'Children');
evt.Key;
switch evt.Key
    case gv.fwdbut
        % get the right button starting at the figure handle hm
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Fix Playback/Lookup')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if strcmp(kid.UserData,gv.fwdbut)
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        playforward(src,evt);
    case gv.bckbut
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Fix Playback/Lookup')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if strcmp(kid.UserData,gv.bckbut)
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        playback(src,evt);
    case gv.cat1but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 1
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat2but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 2
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat3but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 3
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat4but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 4
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat5but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 5
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat6but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 6
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat7but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 7
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat8but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 8
                                src = kids(q);
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat9but
        for p = 1:length(tsrc)
            temp = get(tsrc(p));
            if isfield(temp,'Title')
                if strcmp(temp.Title,'Categories')
                    kids = temp.Children;
                    for q = 1:length(kids)
                        kid = get(kids(q));
                        if isfield(kid,'UserData')
                            if kid.UserData == 9
                                src = kids(q);
                                evt;
                            end
                        end
                    end
                end
            end
        end
        labelfix(src,evt);
    case gv.cat0but
        labelfix(src,evt);   
    otherwise
        disp('Unknown key pressed');
end

end

function savetotext(src,evt)
disp('Saving to text...');
mm1 = get(src,'parent');
hm = get(mm1,'parent');
gv = get(hm,'userdata');
data = gv.data;
filenaam = [gv.resdir gv.fs gv.filmnaam gv.fs gv.filmnaam '.xls'];
while exist(filenaam,'file')
    answer = inputdlg(['File: ', filenaam ,'.xls already exists. Enter a new file name'],'Warning: file already exists',1,{[gv.filmnaam '_01.xls']});
    filenaam = [gv.resdir gv.fs gv.filmnaam gv.fs answer{1}];
end
fid = fopen(filenaam,'w+');
fprintf(fid,[repmat('%s\t',1,12),'%s\n'],'fix nr','fix start (ms)','fix end (ms)','fix dur (ms)','x start','y start','x end','y end','mean x','sd x','mean y','sd y','label');
fgetl(fid);
fprintf(fid,[repmat('%d\t',1,12),'%d\n'],gv.data');
fclose(fid);
disp('... done');
end

% closing and saving function
function sluitaf(src,evt)
gv = get(src,'userdata');
knopsluit = questdlg('You''re about to close the program. Are you sure you''re done and want to quit?','Are you sure?','Yes','No','No');
if strcmp('Yes',knopsluit);
    %     commandwindow;
    disp('Closing...');
    save([gv.resdir gv.fs gv.filmnaam gv.fs gv.filmnaam '.mat']);
    disp('Saving...')
    set(src,'closerequestfcn','closereq');
    close(src);
else
    disp('Program not closed. Continuing.');
end
end

