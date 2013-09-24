function mrotate (varargin)
    global Experiment = 'PSYC4802-20134';
    global Version = '0.9';
    global TestFlag = 0;
    if (nargin > 0)
        HandleInputArguments(varargin{:})
        return;
    end
    try
        RunExperiment();
    catch
        ple();
    end
    Shutdown();
end

function RunExperiment ()
    Initialize();
    RunBlock();
    Deinitialize();
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Block-level functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RunBlock ()
    global par;
    par.trialCounter = 0;
    PresentInstructions();
    PresentPracticePhase();
    PresentExperimentalPhase();
    PresentBlockFeedback();
end

function PresentInstructions ()
    global par;
    ClearScreen();
    mesg = sprintf('Press any button to begin a block of %d trials', par.totalTrials);
    DrawFormattedText(par.mainWindow, mesg, 'center', 'center', par.textColor);
    FlipNow();
    ClearScreen();
    [keyTime, keyCodes] = WaitForButtonPress();
    if (keyCodes(par.abortKey))
        AbortKeyPressed();
    end
    par.tLastOnset = FlipNow();
    par.targNextOnset = par.tLastOnset + 0.500;
end

function PresentPracticePhase ()
    global par;
    par.phaseString = 'practice';
    par.saveData = 0;
    RunManyTrials(par.nPracticeTrials);
end

function PresentExperimentalPhase ()
    global par;
    par.phaseString = 'exp';
    par.saveData = 1;
    RunManyTrials(par.nExperimentalTrials);
end

function RunManyTrials (n)
    global par;
    [samediff, angle] = BalanceTrials(n, 1, par.samediffList, par.angleList);
    for (trial = 1:n)
        par.trialCounter = par.trialCounter + 1;
        Rush('RunOneTrial(samediff{trial}, angle(trial));', ...
             MaxPriority(par.mainWindow));
    end
end

function PresentBlockFeedback ()
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Trial-Level Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RunOneTrial(samediff, angle)
    InitializeTrial(samediff, angle);
    PresentFixation();
    PresentStimuli();
    CollectResponse();
    ProcessResponse(samediff);
    SaveData();
    PresentFeedback();
    TakeABreak();
    EndTrial();
end

function InitializeTrial (samediff, angle)
    global par;
    ClearScreen();
    WaitForAllButtonsToBeReleased();
    par.tLastOnset = Flip(par.targNextOnset);
    par.targNextOnset = par.tLastOnset + par.dur.preTrialBlank;
    % initialize block- and trial-level information for the data storage
    par.trialTimestamp = datestr(now, 'yyyymmdd.HHMMSS');
    par.trialSamediff = samediff;
    par.trialAngle = angle;
    % select stimuli
    PrepareTrialStimuli(samediff, angle);
end

function PrepareTrialStimuli (samediff, angle)
    global par;
    SelectStimuli(samediff);
    SetStimuliLocations();
    if (Randi(2) == 1)
        multiplier = 1;
    else
        multiplier = -1;
    end
    theta = Randi(361) - 1;
    par.stimulusRotations = [theta, mod(theta + multiplier * angle, 360)];
end

function SelectStimuli (samediff)
    global par;
    mirror = Randi(2);
    stimIndex = Randi(size(par.stimList, 1));
    if (par.preloadImages)
        stim1texture = par.stimList(stimIndex, mirror);
        if (strncmpi(samediff, 'same', 4))
            stim2texture = stim1texture;
        else
            stim2texture = par.stimList(stimIndex, 3 - mirror);
        end
    else
        textures = LoadImageAndMirrorImage(par.stimList{stimIndex});
        stim1texture = textures(mirror);
        if (strncmpi(samediff, 'same', 4))
            stim2texture = stim1texture;
        else
            stim2texture = textures(3 - mirror);
        end
    end
    par.stimulusTextures = [stim1texture, stim2texture];
end

function SetStimuliLocations ()
    global par;
    stim1rect = Screen('Rect', par.stimulusTextures(1));
    stim2rect = Screen('Rect', par.stimulusTextures(2));
    separation = par.stimulusSeparationFactor * ...
        max(RectWidth(stim1rect), RectWidth(stim2rect)) / 2;
    stim1rect = OffsetRect(CenterRect(stim1rect, par.mainWindowRect), -1 * separation, 0);
    stim2rect = OffsetRect(CenterRect(stim1rect, par.mainWindowRect), separation, 0);
    par.stimulusRects = [stim1rect', stim2rect'];
end

function PresentFixation ()
    global par;
    ClearDisplay();
    DrawFixation();
    par.tLastOnset = Flip(par.targNextOnset);
    par.targNextOnset = par.tLastOnset + par.dur.fixation;
end

function PresentStimuli ()
    global par;
    ClearDisplay();
    DrawFixation();
    DrawStimuli();
    WaitForAllButtonsToBeReleased();
    par.tLastOnset = Flip(par.targNextOnset);
    par.tDisplayOnset = par.tLastOnset;
end

function CollectResponse ()
    global par;
    [keyTime, keyCodes] = WaitForButtonPress();
    par.tResponseOnset = keyTime;
    par.responseCodes = find(keyCodes);
    ClearScreen();
    WaitForAllButtonsToBeReleased();
    par.tLastOnset = FlipNow();
    par.tDisplayOffset = par.tLastOnset;
end

function ProcessResponse (samediff)
    global par;
    par.trialRT = 1000 * (par.tResponseOnset - par.tDisplayOnset);
    r = par.responseCodes;
    if (any(r == par.abortKey))
        AbortKeyPressed();
        abortAttempt = 1;
    else
        abortAttempt = 0;
    end
    if (abortAttempt)
        par.trialResponse = 'false-abort';
        par.trialAccuracy = -4;
    elseif (isempty(r))
        par.trialResponse = 'none';
        par.trialAccuracy = -1;
    elseif (numel(r) > 1)
        par.trialResponse = 'multi';
        par.trialAccuracy = -2;
    elseif (any(r == par.responses))
        % allowable response
        i = find(r == par.responses);
        par.trialResponse = par.responseString{i};
        if (strcmp(par.trialResponse, samediff))
            par.trialAccuracy = 1;
        else
            par.trialAccuracy = 0;
        end
    else
        par.trialResponse = sprintf('%d', r);
        par.trialAccuracy = -3;
    end
end

function SaveData ()
    global par;
    fid = fopen(par.dataFileName, 'r');
    if (fid == -1)
        fid = fopen(par.dataFileName, 'w');
        if (fid == -1)
            error('cannot create file %s', par.dataFileName);
        end
        fprintf(fid, ['Subject\tExperiment\tVersion\tBlock\tTrialType\t', ...
                      'Trial\tTimestamp\tSameDiff\tRotation\t', ...
                      'Response\tAcc\tRT\n']);
    else
        fclose(fid);
        fid = fopen(par.dataFileName, 'a');
        if (fid == -1)
            error('cannot open file %s', par.dataFileName);
        end
    end
    fprintf(fid, '%d\t%s\t%s\t%s\t%s\t%d\t%s\t%s\t%0.0f\t%s\t%d\t%0.0f\n', ...
            par.subjectID, par.experiment, par.version, par.blockString, ...
            par.phaseString, par.trialCounter, par.trialTimestamp, ...
            par.trialSamediff, par.trialAngle, ...
            par.trialResponse, par.trialAccuracy, par.trialRT);
    fclose(fid);
end

function PresentFeedback ()
    global par;
    ClearDisplay();
    if (par.trialAccuracy ~= -4)
        [fdbkString, fdbkColor] = GenerateFeedback (par.trialAccuracy, par.trialRT);
        DrawFormattedText(par.mainWindow, fdbkString,
                          'center', 'center', fdbkColor);
    end
    par.tLastOnset = FlipNow();
    par.targNextOnset = par.tLastOnset + par.dur.feedback;
end

function [string, color] = GenerateFeedback (acc, rt)
    global par;
    switch acc
      case 1
        mesg = 'CORRECT';
      case 0
        mesg = 'ERROR';
      case -1
        mesg = 'NO RESPONSE';
      case -2
        mesg = 'MULTIPLE RESPONSES';
      case -3
        mesg = 'BAD KEY PRESSED';
      case -4
        % this shouldn't happen, but also shouldn't cause a crash
        mesg = 'TRIAL ABORTED';
      otherwise
        error('accuracy code %0.1f not recognized', acc);
    end
    string = sprintf('TRIAL %d - %s\n\n\nResponse Time = %0.0f ms', ...
                     par.trialCounter, mesg, rt);
    color = par.textColor;
end

function TakeABreak ()
% Pause every N trials, unless there's only one or no trials remaining
    global par;
    if (par.pauseEvery <= 0 || par.trialCounter + 1 >= par.totalTrials || ...
        mod(par.trialCounter, par.pauseEvery) ~= 0)
        return;
    end
    ClearDisplay();
    DrawFormattedText(par.mainWindow,
                      ['You may take a short break\n\n\n\n', ...
                       'Press any button to continue'],
                      'center', 'center', par.textColor);
    par.tLastOnset = Flip(par.targNextOnset);
    ClearScreen();
    [keyTime, keyCodes] = WaitForButtonPress();
    if (keyCodes(par.abortKey))
        AbortKeyPressed();
    end
    par.tLastOnset = FlipNow();
    par.targNextOnset = par.tLastOnset + par.dur.pause;
end

function EndTrial ()
    global par;
    % Wait for post-trial blank
    ClearDisplay();
    par.tLastOnset = Flip(par.targNextOnset);
    par.targNextOnset = par.tLastOnset + par.dur.postTrialBlank;
    if (~par.preloadImages)
        Screen('Close', par.stimulusTextures);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Initialization and Shutdown Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Initialize ()
    InitializePreGraphics();
    InitializeGraphics();
    InitializePostGraphics();
end

function InitializePreGraphics ()
    global TestFlag;
    if (IsMainWindowInitialized())
        error('InitializePreGraphics() called after opening main window');
    end
    AssertOpenGL();
    more('off'); % avoids confusion among novice Matlab/Octave users
    KbName('UnifyKeyNames');

    global par = struct();

    % settings
    par.samediffList = {'same', 'diff'};

    InitializeResponses();

    % durations
    par.dur.preTrialBlank = 0.500;
    par.dur.fixation = 0.500;
    par.dur.feedback = 0.600;
    par.dur.postTrialBlank = 0.250;
    par.dur.pause = 0.500;

    LoadSettingsFile();
    if (TestFlag)
        TestingSettings();
    end
    InitializeExperimenterInput();

    % based on other settings
    par.dataFileName = sprintf('Data-%s-%s-%04d.txt', ...
                               par.experimenter, par.experiment, par.subjectID);
    par.totalTrials = par.nPracticeTrials + par.nExperimentalTrials;
end

function InitializeResponses()
    global par;
    % par.responses should hold one key for same and one key for diff, in that order
    if (IsLinux())
        %par.responses = [KbName('a'), KbName('apostrophe')];
        error('Linux response key names need to be determined');
    else
        par.responses = [KbName('z'), KbName('/?')];
    end
    par.responseString = {'same', 'diff'};
    par.abortKey = KbName('ESCAPE');
    par.yesKey = KbName('y');
    par.noKey = KbName('n');
end

function LoadSettingsFile ()
% Currently a hack.  Load settings that will ultimately be stored in a
% settings file
    global par Experiment Version;
    par.experiment = Experiment;
    par.version = Version;
    par.stimulusSeparationFactor = 2.0;
    par.displayWidth = 300;
    par.displayHeight = 100;
    par.angleList = [20 60 100];
    par.pauseEvery = 50;
    par.backgroundColor = [0 0 0];
    par.textColor = [255 255 255];
    par.preloadImages = 0;
end

function TestingSettings ()
    global par;
    par.experimenter = 'DEF';
    par.subjectID = 999;
    par.blockString = 'Test';
    par.angleList = [45 90];
    par.nPracticeTrials = 1;
    par.nExperimentalTrials = 4;
end

function InitializeExperimenterInput ()
% Get input from experimenter for any fields that are not already set.
    global par;
    if (isfield(par, 'experimenter'))
        experimenterDefault = par.experimenter;
        experimenterFlag = 0;
    else
        experimenterDefault = '';
        experimenterFlag = 1;
    end
    if (isfield(par, 'subjectID'))
        subjectIDDefault = par.subjectID;
        subjectIDFlag = 0;
    else
        subjectIDDefault = '';
        subjectIDFlag = 1;
    end
    if (isfield(par, 'blockString'))
        blockStringDefault = par.blockString;
        blockStringFlag = 0;
    else
        blockStringDefault = '';
        blockStringFlag = 1;
    end
    if (isfield(par, 'angleList'))
        angleListDefault = par.angleList;
        angleListFlag = 0;
    else
        angleListDefault = '';
        angleListFlag = 1;
    end
    if (isfield(par, 'nPracticeTrials'))
        nPracticeTrialsDefault = par.nPracticeTrials;
        nPracticeTrialsFlag = 0;
    else
        nPracticeTrialsDefault = '';
        nPracticeTrialsFlag = 1;
    end
    if (isfield(par, 'nExperimentalTrials'))
        nExperimentalTrialsDefault = par.nExperimentalTrials;
        nExperimentalTrialsFlag = 0;
    else
        nExperimentalTrialsDefault = '';
        nExperimentalTrialsFlag = 1;
    end
    [par.experimenter, par.subjectID, par.blockString, par.angleList, ...
     par.nPracticeTrials, par.nExperimentalTrials] = ...
        ExperimenterInput('Experimenter', experimenterDefault, 's', 0, experimenterFlag, ...
                          'Subject ID', subjectIDDefault, 'i', 0, subjectIDFlag, ...
                          'Condition name', blockStringDefault, 's', 0, blockStringFlag, ...
                          'Rotation (degrees)', angleListDefault, 'v', 0, angleListFlag, ...
                          'Practice trials', nPracticeTrialsDefault, 'i', 0, nPracticeTrialsFlag, ...
                          'Experimental trials', nExperimentalTrialsDefault, 'i', 0, nExperimentalTrialsFlag);
end

function InitializeGraphics ()
    if (IsMainWindowInitialized())
        error('InitializeGraphics() called with main window already open');
    end
    global par;
    Screen('Preference', 'SkipSyncTests', 0);
    Screen('Preference', 'VisualDebugLevel', 4);
    screenNumber=max(Screen('Screens'));
    [par.mainWindow, par.mainWindowRect] = ...
        Screen('OpenWindow', screenNumber, par.backgroundColor, [], 32, 2);
    Screen(par.mainWindow, 'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    HideCursor();
end

function InitializePostGraphics ()
    if (~IsMainWindowInitialized())
        error('InitializePostGraphics() called without an open window');
    endif
    global par;

    % miscellaneous display settings
    [par.mainWindowCenterX, par.mainWindowCenterY] = RectCenter(par.mainWindowRect);
    par.displayRect = CenterRect([0 0 par.displayWidth par.displayHeight], par.mainWindowRect);

    InitializeFixation();

    % calculate frame durations and number of frames
    par.refreshDuration = Screen('GetFlipInterval', par.mainWindow);
    par.slackDuration = par.refreshDuration / 2.0;

    % define fonts
    InitializeFonts();
    SetWindowFont(par.mainWindow, par.textFont, par.textSize, par.textStyle);

    CorrectDurations();

    LoadStimuli();
end

function InitializeFixation ()
    global par;
    par.fixationLines = ComputeFixationLines(par.mainWindowCenterX, par.mainWindowCenterY, 15);
    par.fixationThickness = 1;
    par.fixationColor = [0 250 0];
end

function xy = ComputeFixationLines (x, y, sz)
    xy = [[x - sz; y - sz], [x + sz; y + sz], ...
          [x - sz; y + sz], [x + sz; y - sz]];
end

function InitializeFonts ()
    global par;
    if (IsLinux())
        par.textSize = 32;
        par.textFont = Screen('TextFont', par.mainWindow);
        par.textStyle = 1;
    else
        par.textSize = 24;
        par.textFont = 'Arial';
        par.textStyle = Screen('TextStyle', par.mainWindow);
    end
end

function SetWindowFont(win, font, textSize, textStyle)
    Screen('TextFont', win, font);
    Screen('TextSize', win, textSize);
    Screen('TextStyle', win, textStyle);
end

function CorrectDurations()
% Corrects all durations to even multiples of the refresh duration, with a
% slack amount to give PTB time to prepare for the next flip.  Must be
% called after graphics initialization so the refresh and slack duration
% are known.
    global par;
    fn = fieldnames(par.dur);
    for (i = 1:numel(fn))
        par.dur.(fn{i}) = par.refreshDuration * ...
            round(par.dur.(fn{i}) / par.refreshDuration) - par.slackDuration;
    end
end

function Deinitialize ()
end

function Shutdown ()
    Priority(0);
    fclose('all');
    ShutdownGraphics();
    clear -global;
    clear -all;
end

function ShutdownGraphics ()
    ShowCursor();
    Screen('CloseAll');
end

function HandleInputArguments (varargin)
    global InputArguments
    if (nargin > 0)
        InputArguents.nTrials = varargin{1};
    end
    if (nargin > 1)
        InputArguments.nPracticeTrials = varargin{2};
    end
    if (nargin > 2)
        InputArguments.angles = varargin{3};
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Image Search and Loading Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LoadStimuli ()
    if (~IsMainWindowInitialized())
        error('LoadStimuli() called before main window opened');
    end

    global par;
    stimList = FindStimulusFiles();
    if (par.preloadImages)
        par.stimList = LoadStimulusImages(stimList);
    else
        par.stimList = stimList;
    end
end

function files = FindStimulusFiles()
    directories = {'.', 'stim', ...
                   '~/Dropbox/sync/classes/splab/Experiments/MentalRotation/stim'};
    for (i = 1:numel(directories))
        files = ListImageFiles(directories{i});
        if (~isempty(files))
            directory = directories{i};
            break;
        end
    end
    if (isempty(files))
        error('Cannot find any image files');
    end
end

function files = ListImageFiles (directory)
    imageFileTypes = {'.png', '.jpg', '.jpeg', '.bmp'};
    filesInDir = dir(directory);
    files = cell(numel(filesInDir), 1);
    j = 1;
    for (i = 1:numel(filesInDir))
        if (filesInDir(i).isdir)
            continue;
        end
        [d, basename, ext] = fileparts(filesInDir(i).name);
        if (any(strncmpi(ext, imageFileTypes, 4)))
            files{j} = fullfile(directory, sprintf('%s%s', basename, ext));
            j = j + 1;
        end
    end
    files = files(1:j-1);
end

function textures = LoadStimulusImages (fileList)
    textures = zeros(numel(fileList), 2);
    for (i = 1:numel(fileList))
        textures(i, :) = LoadImageAndMirrorImage(fileList{i});
    end
end

function textures = LoadImageAndMirrorImage (imageFileName)
    global par;
    textures = zeros(1, 2);
    imageMatrix = double(imread(imageFileName));
    % convert to RGB if grayscale
    if ((size(imageMatrix, 3) == 1) || size(imageMatrix, 3) == 2)
        imageMatrix = repmat(imageMatrix(:, :, 1), [1, 1, 3]);
    end
    % remove transparency layer
    if (size(imageMatrix, 3) > 3)
        imageMatrix = imageMatrix(:, :, 1:3);
    end
    % adjust [0, 1] -> [0,255] (seems to be a problem with some pure
    % black/white image files)
    imageValues = unique(imageMatrix(:));
    if (numel(imageValues) == 2 && all(imageValues == [0; 1]))
        imageMatrix(imageMatrix == 1) = 255;
    end
    textures(1) = Screen('MakeTexture', par.mainWindow, imageMatrix);
    textures(2) = Screen('MakeTexture', par.mainWindow, ...
                         imageMatrix(:, end:-1:1, :));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Drawing Routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ClearScreen ()
    global par;
    Screen('FillRect', par.mainWindow, par.backgroundColor);
end

function ClearDisplay ()
    global par;
    Screen('FillRect', par.mainWindow, par.backgroundColor, par.displayRect);
end

function DrawFixation ()
    global par;
    Screen('DrawLines', par.mainWindow, par.fixationLines, ...
           par.fixationThickness, par.fixationColor);
end

function DrawStimuli ()
    global par;
    Screen('DrawTextures', par.mainWindow, par.stimulusTextures, [], ...
           par.stimulusRects, par.stimulusRotations);
end

function flipTime = FlipNow ()
    global par;
    Screen('DrawingFinished', par.mainWindow);
    flipTime = Screen('Flip', par.mainWindow);
end

function flipTime = Flip (targetTime)
    global par;
    Screen('DrawingFinished', par.mainWindow);
    flipTime = Screen('Flip', par.mainWindow, targetTime);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Response-Related Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [time, keys] = WaitForButtonPress ()
    [time, keys] = KbWait();
end

function WaitForAllButtonsToBeReleased ()
    KbReleaseWait();
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Experimenter Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = ExperimenterInput (varargin)
    % Usage:
    %   ExperimenterInput(Prompt1, Default1, Type1, Confirm1, Flag1, ...
    %                     Prompt2, Default2, Type2, Confirm2, Flag2 ...)
    n = nargin;
    if nargout ~= n / 5
        error('input and output arguments must match');
    end
    prompt = varargin(1:5:n);
    defaultValues = varargin(2:5:n);
    inputType = varargin(3:5:n);
    confirmInput = varargin(4:5:n);
    flags = varargin(5:5:n);
    n = numel(prompt);
    varargout = cell(1, nargout);
    for (i = 1:n)
        varargout{i} = GetInput(prompt{i}, defaultValues{i}, inputType{i}, ...
                                confirmInput{i}, flags{i});
    end
end

function response = GetInput (prompt, default, inputType, confirm, flag)
    if (flag)
        printf('\n');
        switch inputType(1)
          case {'d', 'i'}
            response = GetIntegerInput(prompt, default, confirm);
          case 'f'
            response = GetFloatInput(prompt, default, confirm);
          case 's'
            response = GetStringInput(prompt, default, confirm);
          case 'v'
            if (numel(inputType) < 2)
                % default to string type
                subType = 's';
            else
                subType = inputType(2);
            end
            response = GetVectorInput(prompt, default, confirm, subType);
          otherwise
            error('input type %s was not recognized', inputType);
        end
    else
        response = default;
    end
end

function response = GetIntegerInput (prompt, default, confirm)
    done = 0;
    while (~done)
        response = GetResponse(prompt, default);
        [done, response] = ProcessScalarResponse(response, 'i');
        if (done && confirm)
            done = ConfirmResponse(num2str(response));
        end
    end
end

function response = GetFloatInput (prompt, default, confirm)
    done = 0;
    while (~done)
        response = GetResponse(prompt, default);
        [done, response] = ProcessScalarResponse(response, 'f');
        if (done && confirm)
            done = ConfirmResponse(num2str(response));
        end
    end
end

function response = GetStringInput (prompt, default, confirm)
    done = 0;
    while (~done)
        response = GetResponse(prompt, default);
        done = ~isempty(response);
        if (confirm)
            done = ConfirmResponse(response);
        end
    end
end

function response = GetVectorInput (prompt, default, confirm, subtype)
    done = 0;
    while (~done)
        response = GetResponse(prompt, default);
        if (iscell(response))
            [done, response] = ProcessCellArrayResponse(response, subtype);
        else
            [done, response] = ProcessVectorResponse(response, subtype);
        end
        if (done && confirm)
            done = ConfirmResponse(num2str(response));
        end
    end
end

function response = GetResponse (prompt, default)
    prompt2 = SetPrompt(prompt, default);
    fflush(stdout);
    response = input(prompt2, 's');
    if (isempty(response) && ~isempty(default))
        response = default;
    end
end

function promptOut = SetPrompt (promptIn, default)
    if (~isempty(default))
        df = sprintf(' [%s]', default);
    else
        df = '';
    end
    promptOut = sprintf('%s%s: ', promptIn, df);
end

function [success, responseOut] = ProcessScalarResponse(responseIn, rtype)
    if (isempty(responseIn))
        success = 0;
        responseOut = [];
    elseif (any(rtype == 'dif')) % match d/i = integer; f = float
        success = 0;
        [responseOut, n] = sscanf(responseIn, '%f');
        if (n == 1)
            success = 1;
            if (any(rtype == 'di'))
                responseOut = fix(responseOut);
            end
        end
    else
        success = 1;
        responseOut = responseIn;
    end
end

function [success, responseOut] = ProcessCellArrayResponse (responseIn, rtype)
    if (isempty(responseIn))
        success = 0;
        responseOut = {};
        return
    end
    success = 1;
    responseOut = cell(size(responseIn));
    for (i = 1:numel(responseIn))
        if (any(rtype == 'dif'))
            responseOut{i} = str2double(responseIn{i});
        else
            responseOut{i} = responseIn{i};
        end
        if (isnan(responseOut{i}))
            % only reason for non-success is an NaN result from str2double
            success = 0;
        end
    end
end

function [success, responseOut] = ProcessVectorResponse(responseIn, rtype)
    if (isempty(responseIn))
        success = 0;
        responseOut = [];
        return
    end
    responseOut = nan(size(responseIn));
    for (i = 1:numel(responseIn))
        if (any(rtype == 'dif'))
            responseOut(i) = str2double(responseIn(i));
        else
            responseOut(i) = responseIn(i);
        end
    end
    if (any(isnan(responseOut)))
        % only reason for non-success is an NaN result from str2double
        success = 0;
    else
        success = 1;
    end
end

function confirmed = ConfirmResponse(response)
    fprintf('You entered ''%s\''.\nIs this correct? (y/n) ', response);
    done = 0;
    while (~done)
        fflush(stdout);
        r = kbhit();
        if (any(r == 'yYnN'))
            break;
        end
    end
    fprintf('%s\n', r);
    if (any(r == 'yY'))
        confirmed = 1;
    else
        confirmed = 0;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Miscellaneous Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = IsMainWindowInitialized ()
    global par
    tf = exist('par', 'var') && isstruct(par) && isfield(par, 'mainWindow') && ...
         any(par.mainWindow == Screen('Windows'));
end

function AbortKeyPressed ()
    global par;
    if (~IsMainWindowInitialized())
        return;
    end
    ClearScreen();
    string = 'Are you sure you want to terminate the experiment? (y/n)';
    DrawFormattedText(par.mainWindow, string, 'center', 'center',
                      par.textColor);
    FlipNow();
    done = 0;
    while (~done)
        [keyTime, keyCode] = KbPressWait();
        if (keyCode(par.yesKey))
            error('abort key pressed');
        elseif (keyCode(par.noKey))
            done = 1;
        end
    end
    ClearScreen();
    DrawFormattedText(par.mainWindow, 'Resuming experiment.  Please wait...',
                      'center', 'center', par.textColor);
    KbReleaseWait();
    t1 = FlipNow();
    ClearScreen();
    t2 = Flip(t1 + 0.993);
    par.targNextOnset = t2 + .233;
end

%%% Local Variables:
%%% mode:Matlab
%%% End:
