
function pythagoras_tree_matlab_v04
% PYTHAGORAS TREE v0.4
% Random synchronized branch growth.
% Left click: grow selected group.
% 2 / 4: change group size. R: restart. Q / Esc: quit.

%% 1. CONFIGURATION

angleMin = 30;
angleMax = 60;
omega = 0.9;

minRatio = 0.20;       % Minimum branch size: 20% of root
clickCooldown = 0.16;
growthAnimTime = 0.22;

bg = [0.045 0.067 0.125];
panel = [0.065 0.095 0.155];

gold = [0.97 0.79 0.45];
blue = [0.42 0.79 1.00];
cyan = [0.30 0.84 0.76];
green = [0.30 0.86 0.69];
red = [1.00 0.35 0.46];

rng('shuffle');

%% 2. FIGURE AND AXES

fig = figure( ...
    'Name','PYTHAGORAS TREE | One Button', ...
    'NumberTitle','off', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Color',bg, ...
    'Position',[180 80 960 850], ...
    'WindowButtonDownFcn',@onClick, ...
    'WindowKeyPressFcn',@onKey, ...
    'CloseRequestFcn',@onClose);

ax = axes('Parent',fig, ...
    'Position',[0.055 0.105 0.89 0.83], ...
    'Color',bg, ...
    'XColor',bg, ...
    'YColor',bg);

hold(ax,'on');
axis(ax,'equal');
axis(ax,'manual');
axis(ax,'off');

%% 3. GRAPHICS OBJECTS

tri = gobjects(1,4);
edge = gobjects(1,4);
tip = gobjects(1,4);
ghost = gobjects(1,8);
activeOutline = gobjects(1,4);

% Dynamic triangle previews
for k = 1:4

    tri(k) = patch('Parent',ax, ...
        'XData',nan(1,3), ...
        'YData',nan(1,3), ...
        'FaceColor',gold, ...
        'FaceAlpha',0.16, ...
        'EdgeColor',gold, ...
        'LineWidth',1.3, ...
        'Visible','off', ...
        'HitTest','off');

    edge(k) = plot(ax,nan,nan,'-', ...
        'Color',gold, ...
        'LineWidth',2.2, ...
        'Visible','off', ...
        'HitTest','off');

    tip(k) = plot(ax,nan,nan,'o', ...
        'MarkerSize',6, ...
        'MarkerFaceColor',gold, ...
        'MarkerEdgeColor',[1 0.94 0.78], ...
        'Visible','off', ...
        'HitTest','off');

    activeOutline(k) = plot(ax,nan,nan,'-', ...
        'Color',gold, ...
        'LineWidth',1.8, ...
        'Visible','off', ...
        'HitTest','off');
end

% Candidate child squares
for k = 1:8

    ghost(k) = patch('Parent',ax, ...
        'XData',nan(1,4), ...
        'YData',nan(1,4), ...
        'FaceColor',blue, ...
        'FaceAlpha',0.20, ...
        'EdgeColor',blue, ...
        'LineWidth',1.5, ...
        'LineStyle','--', ...
        'Visible','off', ...
        'HitTest','off');
end

%% 4. HUD

text(ax,0.025,0.98,'PYTHAGORAS TREE', ...
    'Units','normalized', ...
    'FontSize',19, ...
    'FontWeight','bold', ...
    'Color',[0.95 0.97 1], ...
    'VerticalAlignment','top', ...
    'HitTest','off');

text(ax,0.027,0.925, ...
    'ONE INPUT  /  INFINITE BRANCHES', ...
    'Units','normalized', ...
    'FontSize',8, ...
    'Color',[0.62 0.70 0.82], ...
    'VerticalAlignment','top', ...
    'HitTest','off');

text(ax,0.027,0.885, ...
    'GROW: Click to expand the highlighted random group.', ...
    'Units','normalized', ...
    'FontSize',8.5, ...
    'Color',[0.84 0.89 0.96], ...
    'VerticalAlignment','top', ...
    'HitTest','off');

ruleText = sprintf( ...
    'STOP: Side < %.0f%% of root.  RED + CLICK: GAME OVER.  No active branches: COMPLETE.', ...
    minRatio*100);

text(ax,0.027,0.852,ruleText, ...
    'Units','normalized', ...
    'FontSize',7.5, ...
    'Color',[0.65 0.75 0.88], ...
    'VerticalAlignment','top', ...
    'HitTest','off', ...
    'Interpreter','none');

statusText = text(ax,0.975,0.975,'READY', ...
    'Units','normalized', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','top', ...
    'FontWeight','bold', ...
    'FontSize',10, ...
    'Color',green, ...
    'BackgroundColor',panel, ...
    'EdgeColor',green, ...
    'Margin',7, ...
    'HitTest','off');

infoText = text(ax,0.025,0.065,'', ...
    'Units','normalized', ...
    'FontSize',9, ...
    'FontWeight','bold', ...
    'Color',[0.92 0.95 1], ...
    'BackgroundColor',panel, ...
    'EdgeColor',[0.16 0.23 0.34], ...
    'Margin',7, ...
    'HitTest','off');

text(ax,0.5,0.015, ...
    'LEFT CLICK: GROW     2 / 4: GROUP     R: RESTART     Q: QUIT', ...
    'Units','normalized', ...
    'HorizontalAlignment','center', ...
    'FontSize',8, ...
    'Color',[0.70 0.77 0.89], ...
    'HitTest','off');

endText = text(ax,0.5,0.51,'', ...
    'Units','normalized', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'FontSize',16, ...
    'FontWeight','bold', ...
    'Color',green, ...
    'BackgroundColor',panel, ...
    'EdgeColor',green, ...
    'LineWidth',1.5, ...
    'Margin',15, ...
    'Visible','off', ...
    'HitTest','off', ...
    'Interpreter','none');

%% 5. GAME STATE

mode = 2;
alive = true;
gameOver = false;
complete = false;

clicks = 0;

rootA = [-0.5 0];
rootB = [0.5 0];

rootLen = norm(rootB-rootA);

root = struct( ...
    'a',rootA, ...
    'b',rootB, ...
    'poly',[rootA;rootB;0.5 -1;-0.5 -1], ...
    'depth',0, ...
    'parent',0, ...
    'expanded',false, ...
    'terminal',false);

squares = root;
selected = [];

fixed = gobjects(0);
recentHandles = gobjects(0);

center = [0 -0.05];
viewHalf = 1.85;

clockStart = tic;
lastClick = -inf;
recentClock = tic;

resetGame();

%% 6. MAIN LOOP

while alive && isgraphics(fig)

    if ~gameOver && ~complete
        p = makePreview(currentAngle());
        drawPreview(p);
    end

    animateGrowth();

    drawnow limitrate;
    pause(0.025);
end

%% ======================= NESTED FUNCTIONS =======================

    function theta = currentAngle()

        theta = 45 + 15*sin(omega*toc(clockStart));

    end

    function resetGame()

        if ~isempty(fixed)
            valid = isgraphics(fixed);
            if any(valid)
                delete(fixed(valid));
            end
        end

        squares = root;
        fixed = gobjects(0);
        recentHandles = gobjects(0);

        clicks = 0;
        gameOver = false;
        complete = false;

        clockStart = tic;
        lastClick = -inf;

        center = [0 -0.05];
        viewHalf = 1.85;

        set(ax, ...
            'XLim',center(1)+[-viewHalf viewHalf], ...
            'YLim',center(2)+[-viewHalf viewHalf]);

        set(endText,'Visible','off');

        fixed = addSquare(root);

        selected = chooseSelection();
        complete = isempty(selected);

        drawPreview(makePreview(currentAngle()));

    end

    function h = addSquare(sq)

        h = patch('Parent',ax, ...
            'XData',sq.poly(:,1), ...
            'YData',sq.poly(:,2), ...
            'FaceColor',depthColor(sq.depth), ...
            'EdgeColor',[0.84 0.91 0.98], ...
            'LineWidth',0.85, ...
            'FaceAlpha',0.91, ...
            'HitTest','off');

        % Keep permanent squares behind dynamic previews.
        uistack(h,'bottom');

    end

    function ids = chooseSelection()

        % Find all squares that can still grow.
        eligible = find( ...
            ~[squares.expanded] & ~[squares.terminal]);

        eligible = eligible(:)';

        ids = [];

        if isempty(eligible)
            return
        end

        % Siblings share the same parent.
        parents = unique([squares(eligible).parent]);

        % 2-mode: choose one sibling group.
        % 4-mode: choose two sibling groups.
        n = min(mode/2,numel(parents));

        order = randperm(numel(parents),n);

        for j = 1:n

            q = parents(order(j));

            same = [squares(eligible).parent] == q;

            ids = [ids eligible(same)]; %#ok<AGROW>

        end

    end

    function p = makePreview(theta)

        p.theta = theta;
        p.ids = selected;

        p.C = zeros(numel(selected),2);

        p.children = struct( ...
            'a',{},'b',{},'poly',{}, ...
            'depth',{},'parent',{}, ...
            'expanded',{},'terminal',{});

        for i = 1:numel(selected)

            id = selected(i);

            [C,L,R] = childSquares( ...
                squares(id),theta);

            L.parent = id;
            R.parent = id;

            p.C(i,:) = C;

            p.children(end+1) = L;
            p.children(end+1) = R;

        end

        p.bad = collisionFlags(p.children,squares);

    end

    function drawPreview(p)

        set(tri,'Visible','off');
        set(edge,'Visible','off');
        set(tip,'Visible','off');
        set(ghost,'Visible','off');
        set(activeOutline,'Visible','off');

        % Highlight selected parent squares and their triangles.
        for i = 1:numel(p.ids)

            id = p.ids(i);
            sq = squares(id);
            C = p.C(i,:);

            T = [sq.a;sq.b;C];

            set(tri(i), ...
                'XData',T(:,1), ...
                'YData',T(:,2), ...
                'Visible','on');

            set(edge(i), ...
                'XData',[sq.a(1) sq.b(1)], ...
                'YData',[sq.a(2) sq.b(2)], ...
                'Visible','on');

            set(tip(i), ...
                'XData',C(1), ...
                'YData',C(2), ...
                'Visible','on');

            P = [sq.poly;sq.poly(1,:)];

            set(activeOutline(i), ...
                'XData',P(:,1), ...
                'YData',P(:,2), ...
                'Visible','on');

        end

        % Draw candidate child squares.
        for k = 1:numel(p.children)

            P = p.children(k).poly;

            if p.bad(k)
                c = red;
            elseif mod(k,2)==1
                c = blue;
            else
                c = cyan;
            end

            set(ghost(k), ...
                'XData',P(:,1), ...
                'YData',P(:,2), ...
                'FaceColor',c, ...
                'EdgeColor',c, ...
                'Visible','on');

        end

        % Status.
        if gameOver

            msg = 'GAME OVER';
            col = red;

        elseif complete || isempty(p.ids)

            msg = 'TREE COMPLETE';
            col = green;

        elseif any(p.bad)

            msg = 'WAIT FOR SAFE ANGLE';
            col = red;

        else

            msg = 'SAFE TO GROW';
            col = green;

        end

        set(statusText, ...
            'String',msg, ...
            'Color',col, ...
            'EdgeColor',col);

        % Statistics.
        terminalCount = sum([squares.terminal]);

        set(infoText,'String',sprintf( ...
            'CLICKS %d     SQUARES %d     ACTIVE %d     STOPPED %d     ANGLE %.1f%c     GROUP %d', ...
            clicks,numel(squares),numel(p.ids), ...
            terminalCount,p.theta,char(176),mode));

        % End-game overlay.
        if gameOver

            message = sprintf( ...
                'GAME OVER\nCollision detected\n%d growths  |  %d squares\nPress R to retry', ...
                clicks,numel(squares));

            set(endText, ...
                'String',message, ...
                'Color',red, ...
                'EdgeColor',red, ...
                'Visible','on');

        elseif complete

            message = sprintf( ...
                'TREE COMPLETE\nAll branches have stopped\n%d growths  |  %d squares\nPress R to play again', ...
                clicks,numel(squares));

            set(endText, ...
                'String',message, ...
                'Color',green, ...
                'EdgeColor',green, ...
                'Visible','on');

        else

            set(endText,'Visible','off');

        end

    end

    function onClick(~,~)

        if ~alive || gameOver || complete
            return
        end

        % Only accept left clicks.
        % The mouse coordinates are deliberately ignored.
        if ~strcmp(get(fig,'SelectionType'),'normal')
            return
        end

        % Prevent accidental double-click growth.
        nowTime = toc(clockStart);

        if nowTime-lastClick < clickCooldown
            return
        end

        lastClick = nowTime;

        p = makePreview(currentAngle());

        finishGrowthAnimation();

        % Clicking a red preview causes failure.
        if any(p.bad)

            gameOver = true;
            drawPreview(p);
            return

        end

        % Mark selected parent nodes as expanded.
        for id = p.ids
            squares(id).expanded = true;
        end

        % Generate permanent child squares.
        newHandles = gobjects(1,numel(p.children));

        for k = 1:numel(p.children)

            sq = p.children(k);

            % Stop branches smaller than 20% of root side.
            sq.terminal = ...
                norm(sq.b-sq.a) < minRatio*rootLen;

            squares(end+1) = sq;

            h = addSquare(sq);

            % New squares start with a short visual highlight.
            set(h, ...
                'FaceAlpha',0.55, ...
                'EdgeColor',gold, ...
                'LineWidth',2.0);

            fixed(end+1) = h;
            newHandles(k) = h;

        end

        recentHandles = newHandles;
        recentClock = tic;

        clicks = clicks+1;

        % Randomly select the next group.
        selected = chooseSelection();

        complete = isempty(selected);

        % Camera changes only after successful growth.
        adjustCamera();

        drawPreview(makePreview(currentAngle()));

    end

    function finishGrowthAnimation()

        if isempty(recentHandles)
            return
        end

        valid = isgraphics(recentHandles);
        recentHandles = recentHandles(valid);

        if ~isempty(recentHandles)

            set(recentHandles, ...
                'FaceAlpha',0.91, ...
                'EdgeColor',[0.84 0.91 0.98], ...
                'LineWidth',0.85);

        end

        recentHandles = gobjects(0);

    end

    function animateGrowth()

        if isempty(recentHandles)
            return
        end

        valid = isgraphics(recentHandles);
        recentHandles = recentHandles(valid);

        if isempty(recentHandles)
            return
        end

        t = toc(recentClock);

        u = min(t/growthAnimTime,1);

        alpha = 0.55 + 0.36*u;
        width = 2.0 - 1.15*u;

        set(recentHandles, ...
            'FaceAlpha',alpha, ...
            'LineWidth',width);

        if u >= 1
            finishGrowthAnimation();
        end

    end

    function adjustCamera()

        pts = vertcat(squares.poly);

        lo = min(pts,[],1);
        hi = max(pts,[],1);

        offset = bsxfun(@minus,pts,center);
        reach = max(abs(offset(:)));

        if reach > 0.82*viewHalf

            % Recenter on the complete tree only after growth.
            center = (lo+hi)/2;

            needed = 0.5*max(hi-lo)*1.30;

            viewHalf = max(viewHalf,needed);

            set(ax, ...
                'XLim',center(1)+[-viewHalf viewHalf], ...
                'YLim',center(2)+[-viewHalf viewHalf]);

        end

    end

    function onKey(~,event)

        switch lower(event.Key)

            case '2'
                mode = 2;
                resetGame();

            case '4'
                mode = 4;
                resetGame();

            case 'r'
                resetGame();

            case {'q','escape'}
                onClose([],[]);

        end

    end

    function onClose(~,~)

        alive = false;

        if isgraphics(fig)
            delete(fig);
        end

    end

end


%% ======================= GEOMETRY FUNCTIONS =======================

function [C,L,R] = childSquares(sq,theta)

A = sq.a;
B = sq.b;

v = B-A;
len = norm(v);

u = v/len;
n = [-u(2) u(1)];

c = cosd(theta);
s = sind(theta);

% Right-angle vertex.
C = A+len*c*c*u+len*s*c*n;

% Left child.
v1 = C-A;
n1 = [-v1(2) v1(1)];

L = struct( ...
    'a',A+n1, ...
    'b',C+n1, ...
    'poly',[A;C;C+n1;A+n1], ...
    'depth',sq.depth+1, ...
    'parent',0, ...
    'expanded',false, ...
    'terminal',false);

% Right child.
v2 = B-C;
n2 = [-v2(2) v2(1)];

R = struct( ...
    'a',C+n2, ...
    'b',B+n2, ...
    'poly',[C;B;B+n2;C+n2], ...
    'depth',sq.depth+1, ...
    'parent',0, ...
    'expanded',false, ...
    'terminal',false);

end


%% ======================= COLLISION DETECTION =======================

function bad = collisionFlags(children,existing)

K = numel(children);

bad = false(1,K);

% New squares against all existing squares.
for i = 1:K

    for j = 1:numel(existing)

        if overlaps(children(i).poly,existing(j).poly)

            bad(i) = true;
            break

        end

    end

end

% New squares against each other.
for i = 1:K

    for j = i+1:K

        if overlaps(children(i).poly,children(j).poly)

            bad([i j]) = true;

        end

    end

end

end


function tf = overlaps(P,Q)

% Positive-area overlap only.
% Edge and vertex contact are allowed.

tol = 1e-10;

% AABB broad-phase test.
lo = max(min(P,[],1),min(Q,[],1));
hi = min(max(P,[],1),max(Q,[],1));

if any(hi-lo <= tol)

    tf = false;
    return

end

% SAT narrow-phase test.
N = [normals(P);normals(Q)];

for i = 1:size(N,1)

    a = P*N(i,:)';
    b = Q*N(i,:)';

    overlap = min(max(a),max(b))-max(min(a),min(b));

    if overlap <= tol

        tf = false;
        return

    end

end

tf = true;

end


function N = normals(P)

E = [P(2:end,:)-P(1:end-1,:); ...
     P(1,:)-P(end,:)];

N = [-E(:,2),E(:,1)];

lens = sqrt(sum(N.^2,2));

good = lens > 1e-10;

N = N(good,:)./lens(good);

end


%% ======================= COLOR SYSTEM =======================

function c = depthColor(d)

% Smooth depth-dependent palette.
pal = [
    0.12 0.31 0.52
    0.13 0.53 0.67
    0.24 0.72 0.61
    0.67 0.79 0.43
    0.95 0.72 0.40
];

t = min(d/16,1)*(size(pal,1)-1);

k = min(floor(t)+1,size(pal,1)-1);

w = t-(k-1);

c = (1-w)*pal(k,:)+w*pal(k+1,:);

end
