function r = Shepard( nTrials )
%SHEPARD Replication of Shepard/Metzler style mental rotation experiment
%   Displays two snake-like cube composite objects for nTrials. On each trial
%   the user enters hits either '1' or '2' denoting the two objects are the
%   same or different object respectively.
%
%   Author: Trystan Larey-Williams
%   Last Revision: 9-8-2009

    KbName('UnifyKeyNames');
    light0Vec = [4 -5 10 0]; % light0 position
    light1Vec = [-4 5 10 0]; % light1 position
    trial = 1;
    db = DataBlock();        % datastruct for experiment results
    trialCallback = db.Callback;
    ListenChar(2);

    try
        InitializeMatlabOpenGL(1);

        screenid=max(Screen('Screens'));
        [win , winRect] = Screen('OpenWindow', screenid);

        Screen('BeginOpenGL', win);
        ar=winRect(4)/winRect(3);

        % Let there be light
        glEnable(GL_LIGHTING);
        glEnable(GL_NORMALIZE);
        glShadeModel( GL_SMOOTH );
        glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE,GL_FALSE);
        glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_TRUE);

        glEnable(GL_LIGHT0);
        glLightfv(GL_LIGHT0,GL_POSITION,light0Vec);
        glLightfv(GL_LIGHT0,GL_DIFFUSE, [ 1 1 1 1 ]);
        glLightfv(GL_LIGHT0,GL_AMBIENT, [ 1 1 1 1 ]);

        glEnable(GL_LIGHT1);
        glLightfv(GL_LIGHT1,GL_POSITION,light1Vec);
        glLightfv(GL_LIGHT1,GL_DIFFUSE, [ 1 1 1 1 ]);
        glLightfv(GL_LIGHT1,GL_AMBIENT, [ 1 1 1 1 ]);

        glEnable(GL_DEPTH_TEST);

        % Load a 'red' material for cubes
        glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT, [ 0 0 0.05 1 ]);
        glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE, [ 0 0 0.8 1 ]);
        glMaterialfv(GL_FRONT_AND_BACK,GL_SHININESS,30.0);
        glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR, [ 0.5 0.5 0.5 1 ]);

        % Set eye back on the z-axis
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity;
        gluPerspective(25,1/ar,0.1,100);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity;
        gluLookAt(0,0,30,0,0,0,0,1,0);
        glClearColor(0,0,0,0);

        % Custom lighting gets rid of some undesired Gouraud artifacts
        LoadPhongShaders();

        obj1 = BuildObject(); % Build the 'cube snake' object
        rx20 = ceil( 1 + 16 * rand() );

        % Main simulation loop
        while(1)
            diff = false;
            obj2 = obj1;
            glClear;
            glPushMatrix();
            glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE, [ 0 0 0.8 1 ]);

            % 50/50 chance of new object
            if round( rand() ) == 1
                diff = true; % TODO, fix possible not different
                obj2 = BuildObject();
            end

            DrawTestObjs( obj1, obj2, rx20 );

            glPopMatrix(); % Blt frame to screen
            Screen('EndOpenGL', win);
            Screen('Flip', win);

            msec = GetSecs();
            hit = 0;
            while(~hit) % Wait for user response
                [hit, secs, code] = KbCheck;
            end
            msec = (GetSecs() - msec) * 1000;

            key = KbName(code); % Store result for this trial
            correct = (strcmp(key, '2@') && diff) || strcmp(key, '1!');
            trial = trial + 1;

            % Change colors to indecate success or failure
            Screen('BeginOpenGL', win);
            glClear;
            glPushMatrix();
            if ~correct
                glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE, [ 0.8 0 0 1 ]);
            elseif correct && ~diff
                trialCallback( msec, rx20*20 );
                glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE, [ 0 0.8 0 1 ]);
            else
                glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE, [ 0 0.8 0 1 ]);
            end
            DrawTestObjs( obj1, obj2, rx20 );
            glPopMatrix(); % Blt frame to screen
            Screen('EndOpenGL', win);
            Screen('Flip', win);

            FlushEvents( 'keyDown' );
            WaitSecs( 0.25 );

            if hit
                if strcmp( key, 'ESCAPE' ) || nTrials < trial
                    break; % All trials complete, exit
                else
                    obj1 = BuildObject(); % Build new object for next trial
                    rx20 = ceil( 1 + 16 * rand() );
                end
            end
            Screen('BeginOpenGL', win);

        end
    catch e
        ListenChar(0);
        Screen('CloseAll');
        throw( e );
    end

    % Cleanup
    ListenChar(0);
    db.Plot();
    Screen('CloseAll');

    r = db; % Return data for evaluation
end

function DrawTestObjs( obj1, obj2, rx20 )
    glPushMatrix(); % Draw object on right side of screen
    glTranslatef( 4.0, 0.0, 0.0 );
    glRotatef( 30, 1, 1, 1 );
    obj1.Center();
    obj1.Draw();
    glPopMatrix();

    glPushMatrix(); % Draw object on left side of screen
    glTranslatef( -4.0, 0.0, 0.0 );
    glRotatef( rx20 * 20, 0, 0, 1 );
    glRotatef( 30, 1, 1, 1 );
    obj2.Center();
    obj2.Draw();
    glPopMatrix();
end

function r = BuildObject()
% Encapsulates drawing functions and transforms to build snake-like
% object from a composition of cubes

    objOrder = [];

    function TranslateX( inverse )
        if inverse
            glTranslatef( -1.0, 0.0, 0.0 );
        else
            glTranslatef( 1.0, 0.0, 0.0 );
        end
    end
    function TranslateY( inverse )
        if inverse
            glTranslatef( 0.0, -1.0, 0.0 );
        else
            glTranslatef( 0.0, 1.0, 0.0 );
        end
    end
    function TranslateZ( inverse )
        if inverse
            glTranslatef( 0.0, 0.0, -1.0 );
        else
            glTranslatef( 0.0, 0.0, 1.0 );
        end
    end

    funcs = {@TranslateX, @TranslateY, @TranslateZ};

    function Center()
        fun = funcs{objOrder(1)};
        fun( true );
        fun = funcs{objOrder(2)};
        fun( true );
        fun = funcs{objOrder(3)};
        fun( true );
        fun = funcs{objOrder(1)};
        fun( true );
    end

    function Draw()
        glPushMatrix();

        % 1st segment
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );
        fun = funcs{objOrder(1)};
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );

        %2nd segment
        fun = funcs{objOrder(2)};
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );

        %3rd segment
        fun = funcs{objOrder(3)};
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );

        %4th segment
        fun = funcs{objOrder(1)};
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );
        fun( false );
        glutSolidCube( 1.0 );
        glutWireCube( 1.0 );

        glPopMatrix();
    end

    indxs = [1 2 3];
    while( numel(funcs) ~= numel(objOrder) )
        n = ceil(numel(indxs) * rand());
        objOrder = [indxs(n) objOrder]; %#ok<AGROW>
        indxs(n) = [];
    end

    r.Draw = @Draw;
    r.Center = @Center;
end

function LoadPhongShaders()
    global GL;

    vert = glCreateShader( GL.VERTEX_SHADER );
    frag = glCreateShader( GL.FRAGMENT_SHADER );

    fh = fopen( 'PhongShader.vert.txt', 'r' );
    source = fread( fh );
    fclose( fh );
    glShaderSource( vert, source );
    glCompileShader( vert );

    fh = fopen( 'PhongShader.frag.txt', 'r' );
    source = fread( fh );
    fclose( fh );
    glShaderSource( frag, source );
    glCompileShader( frag );

    prog = glCreateProgram();

    glAttachShader( prog, vert );
    glAttachShader( prog, frag );

    glLinkProgram( prog );
    glUseProgram( prog );
end
