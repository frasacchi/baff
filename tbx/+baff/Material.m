classdef Material
    %MATERIAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        E = 0
        G = 0;
        rho = 0;
        nu = 0;
        Name = "";
    end

    properties
        yield = nan;    % Yield stress
        uts = nan;      % Ultimate Tensile Strength
    end
    
    methods
        function val = ne(obj1,obj2)
            val = ~(obj1.eq(obj2));
        end
        function obj = ZeroDensity(obj)
            obj.rho = 0;
        end
        function val = eq(obj1,obj2)
            if length(obj1)~= length(obj2) || ~isa(obj2,'baff.Material')
                val = false;
                return
            end
            val = true;
            for i = 1:length(obj1)
                val = val && obj1(i).E == obj2(i).E;
                val = val && obj1(i).G == obj2(i).G;
                val = val && obj1(i).rho == obj2(i).rho;
                val = val && obj1(i).nu == obj2(i).nu;
            end
        end
        function obj = Material(E,nu,rho,Name,opts)
            arguments
                E
                nu
                rho
                Name = "";
                opts.G = nan; % if not nan, overrides setting of G and nu.
                opts.yield = nan;
                opts.uts = nan;
            end
            obj.E = E;
            obj.rho = rho;
            obj.Name = Name;
            obj.nu = nu;
            if isnan(opts.G)
                obj.G  = E / (2 * (1 + nu));
            else
                obj.G  = opts.G;
            end  
            % get yield and UTS ( if only one specified set both as same
            % value
            if ~isnan(opts.yield)
                obj.yield = opts.yield;
                if isnan(opts.uts)
                    obj.uts = obj.yield;
                else
                    obj.uts = opts.uts;
                end
            elseif ~isnan(opts.uts)
                obj.uts = opts.uts;
                obj.yield = opts.uts;
            end
        end
    end
    methods(Static)
        function obj = UniCarbonFibre()
        end

        function obj = Aluminium()
            obj = baff.Material(71.7e9,0.33,2810,yield=5e8);
            obj.Name = "Aluminium7075";
        end
        function obj = IsoCarbonFibre()
            % Quasi-Isotropic Carbon fibre
            obj = baff.Material(60e9,0.3,1600,uts=6e8,G=5e9);
            obj.Name = "IsoCarbonFibre";
        end
        function obj = BlackMetal(factor)
            arguments
                factor = 0;
            end
            % Quasi-Isotropic Carbon fibre
            eta = 1-factor;
            obj = baff.Material(69e9*eta,0.29,1580,uts=6e8*eta,G=8e9*eta);
            obj.Name = "IsoCarbonFibre";
        end
        function obj = Stainless304()
            obj = baff.Material(193e9,0.29,7930);
            obj.Name = "Stainless304";
        end
        function obj = Stainless316()
            obj = baff.Material(193e9,0.27,8000);
            obj.Name = "Stainless316";
        end
        function obj = Stainless400()
            obj = baff.Material(200e9,0.282,7720);
            obj.Name = "Stainless400";
        end
        function obj = Polyamide()
            obj = baff.Material(1.65e9,0.3,3304);
            obj.Name = "Polyamide";
        end
        function obj = Stiff()
            obj = baff.Material(inf,0,0);
            obj.Name = "Stiff";
        end
        function obj = Unity()
            obj = baff.Material(1,-0.5,1);
            obj.Name = "Unity";
        end
    end
end

