function PaperMRT ()
% papermrt
%
% Generates a paper-based MRT test based on Vandenberg & Kuse (1978).
% Creates a LaTeX file, then runs LuaLaTeX to generate a PDF.

    global Version = '0.2';
    try
        Main();
    catch
        ple();
    end
    Shutdown()
end

function LoadSettings ()
    global par;
    par.verbose = 0;
    par.compile = 1;
    par.practiceAngles = ...
        [0,  0, 20, 20;
         20, 20, 60, 60;
         60, 60, 100, 100;
         60, 100, 60, 20];
    par.practiceSameDiff = ...
        {'same', 'diff', 'same', 'diff';
         'diff', 'same', 'same', 'diff';
         'same', 'diff', 'diff', 'same';
         'same', 'diff', 'same', 'diff'};
    par.nForms = 2; % number of experimental forms to generate
    par.nStimuli = 4; % number of comparison stimuli
    par.nMatches = 2; % must be less than number of columns for practice trials
    par.nExperimentalTrials = 20;
    par.angleRange = [20 100];
    par.sameDiff = {'same', 'diff'};
    par.stimulusSize = '1.25in'; % size of stimulus
    par.cellHeight = '1.5in'; % height of stimulus row
    par.cellWidth = '1.6in'; % width of stimulus cell
end

function Main ()
    Initialize();
    RunGenerator();
    Deinitialize();
end

function RunGenerator ()
    GeneratePracticeTests();
    GenerateExperimentTests();
end

function GeneratePracticeTests ()
    global par;
    par.practice = 1;
    par.testName = 'Practice';
    par.fileName = GetFilename(par.testName);
    fid = OpenOutputFile(par.fileName);
    PrintHeader(fid);
    nTrials = size(par.practiceAngles, 1);
    answers = cell(nTrials, 1);
    for (i = 1:nTrials)
        par.trialCounter = i;
        % set angles
        par.trialAngle = NaN(1, par.nStimuli + 1);
        par.trialAngle(1) = GenerateBaseAngle();
        par.trialAngle(2:end) = par.trialAngle(1) + ...
            GenerateMultipliers(par.nStimuli) .* par.practiceAngles(i, 1:par.nStimuli);
        par.trialSameDiff = par.practiceSameDiff(i, 1:par.nStimuli);
        par.trialStimuli = SelectStimuliForTrial(par.trialSameDiff);
        answers(i) = find(strcmpi(par.trialStimuli{1}, par.trialStimuli(2:end)));
        PrintTrialLatexOutput(fid);
    end
    PrintFooter(fid);
    CloseFile(fid);
    par.answerKeyTitle = sprintf('%s %s', par.testName, par.answerKeySuffix);
    answerKeyFileName = GetFilename(par.answerKeyTitle);
    fid = OpenOutputFile(answerKeyFileName);
    GenerateAnswerKeyFile(fid, answers);
    CloseFile(fid);
    if (par.compile)
        CompileFile(par.fileName);
        CompileFile(answerKeyFileName);
    end
end

function GenerateExperimentTests ()
    global par;
    for (i = 1:par.nForms)
        par.testName = sprintf('Test Form %d', i);
        par.fileName = GetFilename(par.testName);
        par.answers = cell(par.nExperimentalTrials);
        fid = OpenOutputFile(par.fileName);
        PrintHeader(fid)
        GenerateExperimentTrials(fid);
        PrintFooter(fid);
        CloseFile(fid);
        par.answerKeyTitle = sprintf('%s %s', par.testName, par.answerKeySuffix);
        answerKeyFileName = GetFilename(par.answerKeyTitle);
        fid = OpenOutputFile(answerKeyFileName);
        GenerateAnswerKeyFile(fid, par.answers);
        CloseFile(fid);
        if (par.compile)
            CompileFile(par.fileName);
            CompileFile(answerKeyFileName);
        end
    end
end

function GenerateExperimentTrials(fid)
    global par;
    for (i = 1:par.nExperimentalTrials)
        par.trialCounter = i;
        % set angles
        par.trialAngle = SelectAnglesForTrial(par.nStimuli);
        par.trialSameDiff = SelectSameDiffForTrial(par.nStimuli, par.nMatches);
        par.trialStimuli = SelectStimuliForTrial(par.trialSameDiff);
        par.answers(i) = find(strcmpi(par.trialStimuli{1}, par.trialStimuli(2:end)));
        PrintTrialLatexOutput(fid);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stimulus Generation

function angles = SelectAnglesForTrial (nStimuli)
% SelectAnglesForTrial
%
% angles = SelectAnglesForTrial (nStimuli) selects enough angles for the
% target and for nStimuli non-targets.
    global par;
    angles = NaN(1, nStimuli + 1);
    angles(1) = GenerateBaseAngle();
    angles(2:end) = angles(1) + ...
        GenerateMultipliers(nStimuli) .* GenerateAnglesFromRange(par.angleRange, nStimuli);
end

function multipliers = GenerateMultipliers (n)
    multipliers = randi(2, 1, n);
    multipliers(multipliers == 2) = -1;
end

function angle = GenerateBaseAngle ()
    angle = GenerateAnglesFromRange([0, 359]);
end

function angles = GenerateAnglesFromRange (range, n)
    if (nargin == 1)
        n = 1;
    end
    angles = randi([min(range), max(range)], 1, n);
end

function samediff = SelectSameDiffForTrial (nStimuli, nMatches)
    samediff = cell(1, nStimuli);
    for (i = 1:nMatches)
        samediff{i} = 'same';
    end
    for (i = (nMatches + 1):nStimuli)
        samediff{i} = 'diff';
    end
    samediff = samediff(randperm(nStimuli));
end

function stimuli = SelectStimuliForTrial (samediff)
    global par;
    nStimuli = numel(samediff);
    stimuli = cell(1, nStimuli);
    sIndex = randi(numel(par.stimulusVariations));
    nReflections = numel(par.stimulusReflections);
    rIndex = randi(nReflections);
    baseName = sprintf('%s%s%s-%s', par.stimulusFileDir, filesep(), ...
                       par.stimulusFileNamePrefix, par.stimulusVariations{sIndex});
    stimuli(1) = sprintf('%s-%d', baseName, par.stimulusReflections{rIndex});
    for (i = 1:nStimuli)
        if (strncmpi(samediff{i}, 'same', 4))
            stimuli(i + 1) = stimuli(1);
        else
            j = mod(rIndex - 1 + randi(nReflections - 1), nReflections) + 1;
            stimuli(i + 1) = sprintf('%s-%d', baseName, par.stimulusReflections{j});
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LaTeX Generation

function PrintHeader (fid)
    global par;
    fprintf(fid, '\\documentclass[12pt]{article}\n');
    fprintf(fid, '\\usepackage[landscape,hmargin=0.5in,top=0.25in,bottom=.75in]{geometry}\n');
    fprintf(fid, '\\usepackage{array,longtable,lastpage}\n');
    fprintf(fid, '\\usepackage{graphicx}\n');
    fprintf(fid, '\\DeclareGraphicsExtensions{.pdf}\n');
    fprintf(fid, '\\usepackage{fontspec}\n');
    fprintf(fid, '\\setmainfont{Helvetica}\n');
    fprintf(fid, '\\usepackage{fancyhdr}\n');
    fprintf(fid, '\\pagestyle{fancy}\n');
    fprintf(fid, '\\fancyhf{}\n');
    fprintf(fid, '\\fancyfoot[C]{\\footnotesize  Page \\thepage\\ of \\pageref{LastPage}}\n');
    fprintf(fid, '\\fancyfoot[R]{\\footnotesize %s}\n', datestr(now, 'yyyymmdd.HHMMSS'));
    fprintf(fid, '\\renewcommand{\\headrulewidth}{0pt}\n');
    fprintf(fid, '\\renewcommand{\\footrulewidth}{0pt}\n');
    %fprintf(fid, '\\newcommand{\\dfwidth}{%s}\n', par.stimulusSize);
    fprintf(fid, '\\begin{document}\n');
    fprintf(fid, '\\begin{center}\n');
    fprintf(fid, '%s\n', par.testName);
    fprintf(fid, '\\end{center}\n');
    % table header
    fprintf(fid, ['\\newcolumntype{B}{>{\\begin{minipage}[c][%s][c]{%s}' ...
                  '\\begin{center}}l<{\\end{center}\\end{minipage}}}\n'], ...
            par.cellHeight, par.cellWidth);
    fprintf(fid, ['\\begin{longtable}{m{2ex}B@{\\hspace{.5in}}', ...
                  repmat('B', 1, par.nStimuli), ...
                  '|m{5ex}} \\hline\n']);
    fprintf(fid, '  & \\multicolumn{1}{c}{Target} \n');
    for (i = 1:par.nStimuli)
        fprintf(fid, '  & \\multicolumn{1}{c}{%s}\n', par.LETTERS{i});
    end
    fprintf(fid, '  & \\multicolumn{1}{c}{Score} \\\\ \\hline \\endhead\n');
    fprintf(fid, '\\multicolumn{%d}{r|}{Page Score} & \\\\ \\hline \\endfoot\n', ...
            par.nStimuli + 2);
    fprintf(fid, '\\multicolumn{%d}{r|}{Page Score} & \\\\ \\hline\n', ...
            par.nStimuli + 2);
    fprintf(fid, '\\multicolumn{%d}{r|}{Total Score} & \\\\ \\hline \\endlastfoot\n', ...
            par.nStimuli + 2);
end

function PrintTrialLatexOutput (fid)
    global par;
    fprintf(fid, '%d ', par.trialCounter);
    for (i = 1:(par.nStimuli+1))
        fprintf(fid, '& \\includegraphics[width=%s,angle=%d]{%s} ', ...
                par.stimulusSize, par.trialAngle(i), par.trialStimuli{i});
        %par.stimulusSize, par.trialAngle(i), 'Stim/HG-A-1');
    end
    fprintf(fid, '& \\\\ \\hline\n');
end

function PrintFooter (fid)
    fprintf(fid, '\\end{longtable}\n');
    fprintf(fid, '\\end{document}\n');
end

function GenerateAnswerKeyFile(fid, answers);
    global par;
    fprintf(fid, '\\documentclass[12pt]{article}\n');
    fprintf(fid, '\\usepackage{fontspec}\n');
    fprintf(fid, '\\setmainfont{Helvetica}\n');
    fprintf(fid, '\\usepackage{lastpage}\n');
    fprintf(fid, '\\usepackage{fancyhdr}\n');
    fprintf(fid, '\\pagestyle{fancy}\n');
    fprintf(fid, '\\fancyhf{}\n');
    fprintf(fid, '\\fancyfoot[C]{\\footnotesize  Page \\thepage\\ of \\pageref{LastPage}}\n');
    fprintf(fid, '\\fancyfoot[R]{\\footnotesize %s}\n', datestr(now, 'yyyymmdd.HHMMSS'));
    fprintf(fid, '\\renewcommand{\\headrulewidth}{0pt}\n');
    fprintf(fid, '\\renewcommand{\\footrulewidth}{0pt}\n');
    fprintf(fid, '\\begin{document}\n');
    fprintf(fid, '\\begin{center}\n');
    fprintf(fid, '%s\n', par.answerKeyTitle);
    fprintf(fid, '\\end{center}\n');
    fprintf(fid, '\\begin{enumerate}\n');
    for (i = 1:size(answers, 1))
        fprintf(fid, '  \\item ');
        a = answers{i};
        for (j = 1:(numel(a)-1))
            fprintf(fid, '%s, ', par.LETTERS{a(j)});
        end
        fprintf(fid, '%s\n', par.LETTERS{a(end)});
    end
    fprintf(fid, '\\end{enumerate}\n');
    fprintf(fid, '\\end{document}\n');
end

function CompileFile (fileName)
    global par;
    for (i = 1:3)
        % run repeatedly to make sure all issues are resolved
        [status, output] = system(sprintf('%s %s ''%s''', par.compiler, ...
                                          par.compilerOptions, fileName));
    end
    if (par.verbose)
        disp(output)
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% File Management

function fileName = GetFilename(prefix, id, suffix)
    if (nargin == 0)
        error('at least one input argument required');
    end
    if (nargin >= 1 && ~ischar(prefix))
        error('first input argument must be a character array');
    end
    if (nargin >= 2 && ~isnumeric(id))
        error('second input argument must be numeric');
    end
    if (nargin >= 3 && ~ischar(suffix))
        error('third input argument must be a character array');
    end
    if (nargin == 1)
        fileName = sprintf('%s.tex', prefix);
    elseif (nargin == 2)
        fileName = sprintf('%s-%d.tex', prefix, id);
    else
        fileName = sprintf('%s-%d-%s.tex', prefix, id, suffix);
    end
end

function fid = OpenOutputFile (fileName)
    fid = fopen(fileName, 'w');
    if (fid == -1)
        error('Cannot open output file %s', fileName);
    end
end

function CloseFile (fid)
    if (nargin >= 1)
        fclose(fid);
    else
        fclose('all');
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Initialization and Shutdown Function

function Initialize ()
    global par = struct();

    % load easily modifiable settings
    LoadSettings();

    % load more rigid settings
    par.samediffList = {'same', 'diff'};
    par.LETTERS = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', ...
                   'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', ...
                   'U', 'V', 'W', 'X', 'Y', 'Z'};
    par.compiler = 'lualatex';
    par.compilerOptions = '';
    par.stimulusFileDir = 'Stim';
    par.stimulusFileNamePrefix = 'HG';
    par.stimulusVariations = {'A', 'B'};
    par.stimulusReflections = {1, 2};
    par.answerKeySuffix = 'Answer Key';
end

function Deinitialize ()
end

function Shutdown ()
    fclose('all');
    clear -global;
    clear -all;
end

%%% Local Variables:
%%% mode:Matlab
%%% End:
