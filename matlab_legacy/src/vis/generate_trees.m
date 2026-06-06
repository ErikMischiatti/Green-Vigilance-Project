function [XYZ_leaf, health_leaf, trees, XYZtr_all] = generate_trees(bounds, nTrees, varargin)
%GENERATE_TREES  Procedural tree canopies with realistic 3D leaf clusters.
%
%   [XYZ_leaf, health_leaf, trees, XYZtr_all] = GENERATE_TREES([x0 x1; y0 y1; z0 z1], nTrees, ...)
%
%   Options (name/value pairs):
%
%     'Seed'               []          
%         Seme per il generatore random (rng).
%         - [] : usa il RNG corrente (casualità diversa ad ogni run).
%         - numero (es. 42): genera sempre la stessa disposizione (riproducibile).
%
%     'LeavesPerTree'      [120 280]   
%         Range del numero di foglie per albero.
%         Controlla la densità della chioma (più foglie → chiome più piene).
%
%     'HeightRange'        [4 7]       
%         Range di altezze totali degli alberi (m).
%
%     'CanopyBaseFrac'     [0.55 0.75] 
%         Frazione dell’altezza totale a cui inizia la chioma.
%         Es.: 0.6 → chioma da 60% in su, quindi tronco più lungo.
%
%     'MinCanopyClearance' 1.2         
%         Altezza minima (m) dal suolo sotto la quale non compaiono foglie.
%         Ha priorità su 'CanopyBaseFrac'.
%
%     'CrownRadiusXY'      [2.0 4.5]   
%         Range del raggio orizzontale medio della chioma (m).
%
%     'ShapePower'         [1.6 2.4]   
%         Esponente per la forma della chioma (super-ellissoide).
%         - Valori bassi (~1.5): chiome più tonde.
%         - Valori alti (>2): chiome più allungate/appiattite.
%
%     'Lobes'              [1 3]       
%         Numero di lobi laterali che rendono la chioma irregolare.
%         - 0: sfera liscia.
%         - 2–3: forma più realistica con rami laterali.
%
%     'TrunkRadius'        [0.12 0.22] 
%         Raggio del tronco (m), usato solo per disegno opzionale del tronco.
%
%     'TreeHealthMap'      [] | @(x,y)->valore
%         Funzione che, data la posizione (x,y), restituisce la salute [0,1].
%         - [] : usa un pattern predefinito a zone casuali sane/malate.
%
%     'LeafJitter'         0.15        
%         Rumore gaussiano (m) sulle posizioni delle foglie.
%         Valori più alti → chiome più disordinate.
%
%   Output:
%     XYZ_leaf     Nx3 coordinate delle foglie.
%     health_leaf  Nx1 valori di salute [0–1].
%     trees        Struct array con info su ogni albero (centro, raggio, ecc.).
%     XYZtr_all    Punti del tronco (separati dalle foglie).


p = inputParser;
p.addParameter('Seed',[]);
p.addParameter('LeavesPerTree',[120 280]);
p.addParameter('HeightRange',[4 7]);
p.addParameter('CanopyBaseFrac',[0.55 0.75]);
p.addParameter('MinCanopyClearance',1.2);
p.addParameter('CrownRadiusXY',[2.0 4.5]);
p.addParameter('ShapePower',[1.6 2.4]);
p.addParameter('Lobes',[1 3]);
p.addParameter('TrunkRadius',[0.12 0.22]);
p.addParameter('TreeHealthMap',[]);
p.addParameter('LeafJitter',0.15);
p.parse(varargin{:});
opt = p.Results;


% PER SALVARE GLI INDICI DELLE FOGLIE (DA APPLICARE)
% i0 = size(XYZ_leaf,1) + 1;
% % ... (dopo aver costruito XYZt)
% XYZ_leaf    = [XYZ_leaf; XYZt];
% health_leaf = [health_leaf; clamp01( th + 0.12*randn(size(XYZt,1),1) )];
% i1 = size(XYZ_leaf,1);
% trees(t).leafIdx = [i0 i1];



if ~isempty(opt.Seed), rng(opt.Seed); end

xL = bounds(1,:); yL = bounds(2,:); zL = bounds(3,:);

XYZ_leaf    = [];
health_leaf = [];
XYZtr_all   = [];
trees  = struct('center',{},'rXY',{},'rZ',{},'health',{},'nLeaves',{},'zCanopyBase',{},'trunk',{});

for t = 1:nTrees
    % --- params albero
    H      = randRange(opt.HeightRange);
    fBase  = randRange(opt.CanopyBaseFrac);
    zBase  = zL(1);
    zCanopyBase = max(zBase + opt.MinCanopyClearance, zBase + fBase*H);
    zTop   = zBase + H;
    rZ     = 0.5*(zTop - zCanopyBase);
    cz     = zCanopyBase + rZ;
    rXY    = randRange(opt.CrownRadiusXY);
    powK   = randRange(opt.ShapePower);
    nLobes = randi(opt.Lobes);
    nLeaf  = randi(opt.LeavesPerTree);

    cx = randRange([xL(1)+rXY+2, xL(2)-rXY-2]);
    cy = randRange([yL(1)+rXY+2, yL(2)-rXY-2]);
    center = [cx cy cz];

    % salute per albero
    if isa(opt.TreeHealthMap,'function_handle')
        th = clamp01( opt.TreeHealthMap([cx cy]) );
    else
        th = 1.0;
        if (cy > 120) || (cx > 120 && cy > 80) || (cx < 60 && cy > 90)
            th = 0.25 + 0.1*rand;
        else
            th = 0.75 + 0.2*rand;
        end
        th = clamp01(th);
    end

    % --- chioma (solo foglie) SOPRA la base chioma
    nMain   = round(0.65*nLeaf);
    nRemain = nLeaf - nMain;
    XYZt = sampleSuperEllipsoid(center, rXY, rZ, powK, nMain);

    if nLobes>0
        ang = rand(nLobes,1)*2*pi;
        off = (0.4+0.35*rand(nLobes,1))*rXY;
        for j=1:nLobes
            c2 = center + [off(j)*cos(ang(j))  off(j)*sin(ang(j))  rZ*(rand-0.2)*0.3];
            r2 = rXY*(0.55+0.2*rand);
            z2 = rZ *(0.6+0.25*rand);
            n2 = max(8, round(nRemain/nLobes));
            XYZt = [XYZt; sampleSuperEllipsoid(c2, r2, z2, powK, n2)]; %#ok<AGROW>
        end
    end

    % jitter + clamp sopra la base chioma
    XYZt = XYZt + opt.LeafJitter*randn(size(XYZt));
    XYZt(:,3) = max(XYZt(:,3), zCanopyBase + 0.05);

    % --- tronco (separato)
    nTrunk = max(3, round(0.02*nLeaf));
    trR    = randRange(opt.TrunkRadius);
    tz     = linspace(zBase, zCanopyBase, nTrunk)';
    txy    = trR * (randn(nTrunk,2)*0.2);
    XYZtr  = [cx + txy(:,1), cy + txy(:,2), tz];

    % --- accumula (foglie e tronco separati)
    XYZ_leaf    = [XYZ_leaf; XYZt]; %#ok<AGROW>
    health_leaf = [health_leaf; clamp01( th + 0.12*randn(size(XYZt,1),1) )]; %#ok<AGROW>
    XYZtr_all   = [XYZtr_all; XYZtr]; %#ok<AGROW>

    trees(t).center      = center;
    trees(t).rXY         = rXY;
    trees(t).rZ          = rZ;
    trees(t).health      = th;
    trees(t).nLeaves     = size(XYZt,1);
    trees(t).zCanopyBase = zCanopyBase;
    trees(t).trunk       = XYZtr;
end
end

% ---- helpers
function P = sampleSuperEllipsoid(c, rxy, rz, powK, N)
U = rand(N,1).^(1/3.5);
phi = 2*pi*rand(N,1);
cost = 2*rand(N,1)-1;
theta = acos(cost);
sx = (abs(sin(theta).*cos(phi))).^(2/powK).*sign(sin(theta).*cos(phi));
sy = (abs(sin(theta).*sin(phi))).^(2/powK).*sign(sin(theta).*sin(phi));
sz = (abs(cos(theta))).^(2/powK).*sign(cos(theta));
X = rxy * U .* sx + c(1);
Y = rxy * U .* sy + c(2);
Z = rz  * U .* sz + c(3);
P = [X Y Z];
end

function y = randRange(ab), y = ab(1) + (ab(2)-ab(1))*rand; end
function y = clamp01(x),     y = min(max(x,0),1);             end
