classdef Airfoil < handle
    %Airfoil Represents an airfoil with geometry and aerodynamic properties.
    properties
        Name string % Name of the airfoil
        NormArea     % Normalized area
        Cl_max       % Maximum lift coefficient
        Etas (:,1) double % Normalized chordwise locations
        Ys (:,2) double   % Upper and lower surface thickness distribution
    end
    properties(GetAccess=private)
        PolyPerim % polynomial coefienct for thickness to chord fit
        Thickness
        CumArea % Cumulative area 
    end
    properties(GetAccess=private,SetAccess=private)
        cEta_last = [nan;nan];
        CutArea_last = nan;
    end

properties(Dependent)
    NEta
end
methods
    function NEta = get.NEta(obj)
        NEta = length(obj.Etas);
    end
end
methods
    function obj = Airfoil(name, Cl_max, etas, ys)
        %AIRFOIL Construct an Airfoil object
        obj.Name = name;
        obj.Cl_max = Cl_max;
        obj.Etas = etas;
        obj.Ys = ys;
        obj.Thickness = abs(ys(:,1)-ys(:,2));
        obj.CumArea = cumtrapz(etas,obj.Thickness);
        obj.NormArea = obj.CumArea(end);

        % get fit for perimeter
        tcs = linspace(0,0.2,6);
        ps = tcs*0;

        X = [[etas;flipud(etas)],[ys(:,1);flipud(ys(:,2))]]';
        dX = X(:,2:end)-X(:,1:end-1);
        for i = 1:6
            ps(i) = sum(vecnorm(dX.*[1;tcs(i)]));
        end
        obj.PolyPerim = polyfit(tcs,ps,5);
    end
    function val = Perimeter(obj,chord,tc)
        if isscalar(obj)
            val = polyval(obj.PolyPerim,tc)*chord;
        else
            N = length(obj);
            val = ones(1,N);
            if isscalar(chord)
                chord = val * chord;
            elseif length(chord) ~= N
                error('Length of chord must be 1 or same as Airfoil length')
            end
            if isscalar(tc)
                tc = val * tc;
            elseif length(tc) ~= N
                error('Length of chord must be 1 or same as Airfoil length')
            end
            for i = 1:N
                val(i) = polyval(obj(i).PolyPerim,tc(i));
            end
            val = val.*chord;
        end
    end
    function val = CutArea(obj,cEta)
        if all(cEta==obj.cEta_last)
            val = obj.CutArea_last;
        else
            tmp = interp1(obj.Etas,obj.CumArea,cEta);
            val = tmp(2)-tmp(1);
            obj.cEta_last = cEta;
            obj.CutArea_last = val;
        end
    end
    function val = Area(obj,chord,tc,cEta)
        arguments
            obj 
            chord (1,:) double = 1
            tc (1,:) double = 1
            cEta (2,:) double = [nan;nan]
        end
        if isscalar(obj)
            if isnan(cEta(1))
                val = chord.^2*tc*obj.NormArea;
            else
                val = chord.^2*tc*obj.CutArea(cEta(:,1));
            end
        else
            N = length(obj);
            val = ones(1,N);
            if isscalar(chord)
                chord = val * chord;
            elseif length(chord) ~= N
                error('Length of chord must be 1 or same as Airfoil length')
            end
            if isscalar(tc)
                tc = val * tc;
            elseif length(tc) ~= N
                error('Length of chord must be 1 or same as Airfoil length')
            end
            if size(cEta,2)==1
                cEta = repmat(cEta,1,N);
            elseif size(cEta,2) ~= N
                error('Size of cEta must be 2x1 or 2x(Airfoil length)')
            end
            val = chord.^2.*tc;
            if isnan(cEta(1))
                val = val.*[obj.NormArea];
            else
                for i = 1:N
                    val(i) = val(i).*obj(i).CutArea(cEta(:,i));
                end
            end
        end
    end
    function val = Hash(obj)
        % A unique number used to sort / indentify unique Airfoils.
        val = zeros(size(obj));
        for i = 1:length(val)
            val(i) = sum(double(char(obj(i).Name))) + obj(i).NormArea + sum(obj(i).Ys,"all") + obj(i).NEta;
        end
    end
    function val = eq(obj1,obj2)
        %overloads the == operator to check the equality of two Airfoil objects.
        if length(obj1)~= length(obj2) || ~isa(obj2,'baff.Airfoil')
            val = false;
            return
        end
        val = true;
        for i = 1:length(obj1)
            val = val && obj1(i).Name == obj2(i).Name;
            val = val && obj1(i).NormArea == obj2(i).NormArea;
        end
    end
    function ToBaff(obj,filepath,loc)
        %TOBAFF Write a beam BAFF object to a HDF5 file.
        %Args:
        %   filepath (string): Path to file
        %   loc (string): Location in file
        N = length(obj);
        if N == 0
            h5writeatt(filepath,[loc,'/Airfoils/'],'Qty', 0);
            return
        end
    
        h5write(filepath,sprintf('%s/Airfoils/Name',loc),[obj.Name],[1 1],[1 N]);
        h5write(filepath,sprintf('%s/Airfoils/Cl_max',loc),[obj.Cl_max],[1 1],[1 N]);
        ac_Etas = zeros(max([obj.NEta]),N)*nan;
        ac_Ys = zeros(max([obj.NEta]),N*2)*nan;
        for i = 1:N
            ac_Etas(1:obj(i).NEta,i) = obj(i).Etas;
            ac_Ys(1:obj(i).NEta,(i*2-1):(i*2)) = obj(i).Ys;
        end
        h5write(filepath,sprintf('%s/Airfoils/Etas',loc),ac_Etas,[1 1],[size(ac_Etas,1) N]);
        h5write(filepath,sprintf('%s/Airfoils/Ys',loc),ac_Ys,[1 1],[size(ac_Etas,1) N*2]);    
        h5writeatt(filepath,[loc,'/Airfoils/'],'Qty', N);
    end
    
    function vals = GetNormArea(obj,cEtas)
        %GetNormArea returns the normalized area of the airfoil between two chordwise locations.
        %Args:
        %   cEtas (1,2) double: Chordwise locations to integrate between, default [0 1]
        arguments
            obj
            cEtas (1,2) double = [0 1]
        end
        vals = zeros(size(obj));
        for i = 1:length(obj)
            thickness = obj(i).Ys(:,1) - obj(i).Ys(:,2);
            eta = obj(i).Etas;
            idx = eta > cEtas(1) & eta < cEtas(2);
            etas = [cEtas(1);eta(idx);cEtas(2)];
            thickness = [interp1(eta,thickness,cEtas(1));thickness(idx);interp1(eta,thickness,cEtas(2))];
            vals(i) = trapz(etas,thickness);
        end
    end
end
methods(Static)
    function obj = FromBaff(filepath,loc)
        %FROMBAFF build a beam BAFF object from a HDF5 file.
        %Args:
        %   filepath: path to the HDF5 file
        %   loc: location in the HDF5 file where the beam data is stored
        Qty = h5readatt(filepath,[loc,'/Airfoils/'],'Qty');
        obj = baff.Airfoil.empty;
        if Qty == 0    
            return;
        end
        %% create aerostations
        Names = h5read(filepath,sprintf('%s/Airfoils/Name',loc));
        iCl_max = h5read(filepath,sprintf('%s/Airfoils/Cl_max',loc));
        iEtas = h5read(filepath,sprintf('%s/Airfoils/Etas',loc));
        iYs = h5read(filepath,sprintf('%s/Airfoils/Ys',loc));
        for i = 1:Qty
            obj(i) = baff.Airfoil(Names(i),iCl_max(i),iEtas(:,i),iYs(:,(i*2-1):(i*2)));
        end
    end
    function TemplateHdf5(filepath,loc)
        %TEMPLATEHDF5 Create a template for the Beam BAFF object in an HDF5 file.
        %Args:
        %   filepath (string): Path to the HDF5 file
        %   loc (string): Location in the file where the Beam data will be stored

        %create placeholders
        h5create(filepath,sprintf('%s/Airfoils/Name',loc),[1 inf],"Chunksize",[1,10],"Datatype","string");
        h5create(filepath,sprintf('%s/Airfoils/Cl_max',loc),[1 inf],"Chunksize",[1,10]);
        h5create(filepath,sprintf('%s/Airfoils/Etas',loc),[inf inf],"Chunksize",[100,10]);
        h5create(filepath,sprintf('%s/Airfoils/Ys',loc),[inf inf],"Chunksize",[100,10]);
    end
    function obj = NACA(pCamber,pLocCamber,tThickness)
        % NACA 4-digit airfoil generator
        % pCamber: Camber percentage
        % pLocCamber: Camber location percentage
        % tThickness: actual t/c for wetted perimeter (drag); default 0.12
        % ys/NormArea always use t=1 for structural sizing compatibility
        arguments
            pCamber
            pLocCamber
            tThickness = 0.12
        end
        etas = 0:0.02:1;
        % ys and NormArea: t=1 (structural sizing, unchanged from original)
        yt = 5*1*(0.2969*sqrt(etas)-0.126*etas-0.3516*etas.^2+0.2843*etas.^3-0.1015*etas.^4);
        m = pCamber/100;
        p = pLocCamber/10;
        yc = m/p^2*((1-2*p)+2*p*etas-etas.^2);
        yc(etas>=p) = m/(1-p)^2*(1-2*p+2*p*etas(etas>=p)-etas(etas>=p).^2);
        ys = [yt;-yt] + repmat(yc,2,1);
% <<<<<<< Updated upstream
% =======
        Area = trapz(etas,yt)*2;
        % Perimeter: compute from actual thickness for correct drag/wetted area
        yt_p = 5*tThickness*(0.2969*sqrt(etas)-0.126*etas-0.3516*etas.^2+0.2843*etas.^3-0.1015*etas.^4);
        X_p = [etas; yt_p];
        perimeter = sum(vecnorm(X_p(:,2:end)-X_p(:,1:end-1)))*2;
% >>>>>>> Stashed changes
        name = sprintf('NACA%.0f%.0f',round(pCamber),round(pLocCamber));
        obj = baff.Airfoil(name,1.5,etas',ys');
    end
    function obj = NACA_sym()
        persistent defaultAirfoil
        if isempty(defaultAirfoil)
            etas = 0:0.02:1;
            % ys/NormArea: t=1 (structural, unchanged from original)
            yt = 5*1*(0.2969*sqrt(etas)-0.126*etas-0.3516*etas.^2+0.2843*etas.^3-0.1015*etas.^4);
            ys = [yt;-yt];
            defaultAirfoil = baff.Airfoil('NACA',1.5,etas',ys');
        end
        obj = defaultAirfoil;
    end
    function obj = SC2_0614()
        % http://airfoiltools.com/airfoil/details?airfoil=sc20614-il
        persistent sc2
        if isempty(sc2)
            etas = [0,0.002,0.005,0.01:0.01:1];
            ys = [0	0.0108	0.0166	0.0225	0.0298	0.0349	0.0387	0.0418	0.0445	0.0468	0.0489	0.0508	0.0525	0.0541	0.0555	0.0568	0.058	0.0591	0.0602	0.0612	0.0621	0.0629	0.0637	0.0644	0.0651	0.0657	0.0663	0.0668	0.0673	0.0678	0.0682	0.0686	0.0689	0.0692	0.0694	0.0696	0.0698	0.0699	0.07	0.0701	0.0701	0.0701	0.0701	0.07	0.0699	0.0698	0.0696	0.0694	0.0692	0.069	0.0687	0.0684	0.0681	0.0677	0.0673	0.0669	0.0664	0.0659	0.0653	0.0647	0.064	0.0633	0.0626	0.0618	0.061	0.0601	0.0591	0.0581	0.057	0.0559	0.0547	0.0535	0.0522	0.0509	0.0495	0.0481	0.0466	0.0451	0.0436	0.042	0.0404	0.0387	0.037	0.0352	0.0334	0.0316	0.0297	0.0278	0.0258	0.0238	0.0218	0.0197	0.0176	0.0154	0.0132	0.0109	0.0086	0.0062	0.0038	0.0013	-0.0013	-0.0039	-0.0066;...
                    0	-0.0108	-0.0166	-0.0225	-0.0298	-0.0349	-0.0388	-0.0419	-0.0446	-0.0469	-0.049	-0.0509	-0.0526	-0.0542	-0.0557	-0.057	-0.0582	-0.0594	-0.0605	-0.0615	-0.0624	-0.0633	-0.0641	-0.0648	-0.0655	-0.0661	-0.0667	-0.0672	-0.0677	-0.0681	-0.0685	-0.0688	-0.0691	-0.0693	-0.0695	-0.0697	-0.0698	-0.0699	-0.0699	-0.0698	-0.0697	-0.0696	-0.0694	-0.0692	-0.0689	-0.0686	-0.0682	-0.0677	-0.0672	-0.0666	-0.0659	-0.0651	-0.0642	-0.0632	-0.0622	-0.0611	-0.0599	-0.0586	-0.0572	-0.0557	-0.0541	-0.0525	-0.0508	-0.0491	-0.0473	-0.0455	-0.0436	-0.0417	-0.0397	-0.0377	-0.0356	-0.0336	-0.0315	-0.0294	-0.0274	-0.0253	-0.0233	-0.0213	-0.0193	-0.0174	-0.0155	-0.0137	-0.0119	-0.0102	-0.0086	-0.0072	-0.0059	-0.0047	-0.0037	-0.0029	-0.0023	-0.0019	-0.0017	-0.0017	-0.0019	-0.0024	-0.0031	-0.0041	-0.0054	-0.0069	-0.0087	-0.0108	-0.0132];
            ys = ys./max(ys(1,:)-ys(2,:));
            sc2 = baff.Airfoil('SC2_0614',1.5,etas',ys');
        end
        obj = sc2;
    end
end
end