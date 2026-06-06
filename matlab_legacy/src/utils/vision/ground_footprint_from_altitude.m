function poly = ground_footprint_from_altitude(cam, pose)
%GROUND_FOOTPRINT_FROM_ALTITUDE  Intersezione (z=0) ∩ frustum: poligono in XY.
%   Ritorna Nx2 (ordinato CCW). [] se nessuna intersezione non-degenerata.

% Frustum in world
[V,~] = camera_frustum_vertices(cam, pose);

% Indici spigoli del frustum (12 edges)
E = [1 2; 2 3; 3 4; 4 1;   % near
     5 6; 6 7; 7 8; 8 5;   % far
     1 5; 2 6; 3 7; 4 8];  % pillars

epsZ = 1e-9;
pts = [];

% Intersezione ogni spigolo con piano z=0
for k = 1:size(E,1)
    i = E(k,1); j = E(k,2);
    A = V(i,:); B = V(j,:);
    zA = A(3);  zB = B(3);

    % Se uno dei due è quasi sul piano, prendi direttamente il punto
    if abs(zA) < epsZ && abs(zB) < epsZ
        % l’intero edge è sul piano: tieni i due estremi
        pts = [pts; A(1:2); B(1:2)]; %#ok<AGROW>
        continue
    elseif abs(zA) < epsZ
        pts = [pts; A(1:2)]; %#ok<AGROW>
        continue
    elseif abs(zB) < epsZ
        pts = [pts; B(1:2)]; %#ok<AGROW>
        continue
    end

    % Cambio di segno → c'è intersezione
    if (zA > 0 && zB < 0) || (zA < 0 && zB > 0)
        t = -zA / (zB - zA);   % parametro su [0,1]
        if t >= 0 && t <= 1
            P = A + t*(B - A);
            pts = [pts; P(1:2)]; %#ok<AGROW>
        end
    end
end

% Deduplica con tolleranza
if isempty(pts)
    poly = [];
    return
end
pts = unique(round(pts,6),'rows');

% Se meno di 3 punti → niente poligono
if size(pts,1) < 3
    poly = [];
    return
end

% Ordina i vertici in senso antiorario (convex hull)
K = convhull(pts(:,1), pts(:,2));
poly = pts(K(1:end-1),:);   % convhull ripete il primo punto alla fine
end
