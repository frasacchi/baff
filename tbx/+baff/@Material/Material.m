classdef Material
    %MATERIAL Class to describe material properties
    properties
        E = 0; % Young's modulus
        G = 0; % Shear modulus, if not provided it is calculated from E and nu
        rho = 0; % Density
        nu = 0; % Poisson's ratio
        Name = ""; % Name of the material
    end

    properties
        yield = nan;    % Yield stress
        uts = nan;      % Ultimate Tensile Strength
    end
    methods (Static)
        obj = FromBaff(filepath,loc);
        TemplateHdf5(filepath,loc);
    end
    
    methods
        function val = Hash(obj)
            %HASH returns a unique number used to sort / indentify unique Materials.
            val = zeros(size(obj));
            for i = 1:length(val)
                val(i) = sum(double(char(obj(i).Name))) + obj(i).E + obj(i).G + obj(i).rho + obj(i).nu;
            end
        end
        function val = ne(obj1,obj2)
            %overloads the ~= operator to check the inequality of two Material objects.
            val = ~(obj1.eq(obj2));
        end
        function obj = ZeroDensity(obj)
            %ZERODENSITY sets the density of the material to zero.
            obj.rho = 0;
        end
        function val = eq(obj1,obj2)
            %overloads the == operator to check the equality of two Material objects.
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
            %MATERIAL Construct an instance of this class
            %Args:
            %   E (double): Young's modulus
            %   nu (double): Poisson's ratio
            %   rho (double): Density
            %   Name (string): Name of the material
            %   opts.G (double): Shear modulus, if not provided it is calculated from E and nu
            %   opts.yield (double): Yield stress, if not provided it is set to nan
            %   opts.uts (double): Ultimate Tensile Strength, if not provided it is set to yield stress
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
        function obj = Aluminium()
            % Static mthod to create an Aluminium material
            % E=71.7e9, nu=0.33, rho=2810
            persistent al
            if isempty(al)
                al = baff.Material(71.7e9,0.33,2810,yield=5e8);
                al.Name = "Aluminium7075";
            end
            obj = al;
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
            % Static method to create a Stainless Steel 304 material
            % E=193e9, nu=0.29, rho=7930
            persistent m
            if isempty(m)
                m = baff.Material(193e9,0.29,7930);
                m.Name = "Stainless304";
            end
            obj = m;
        end
        function obj = Stainless4310()
            % Static method to create a Stainless Steel 304 material
            % E=193e9, nu=0.29, rho=7930
            persistent m
            if isempty(m)
                m = baff.Material(193e9,0.3403,7930);
                m.Name = "Stainless4310";
            end
            obj = m;
        end
        function obj = Stainless316()
            % Static method to create a Stainless Steel 316 material
            % E=193e9, nu=0.3, rho=8000
            persistent m
            if isempty(m)
                m = baff.Material(193e9,0.27,8000);
                m.Name = "Stainless316";
            end
            obj = m;
        end
        function obj = Stainless400()
            % Static method to create a Stainless Steel 400 material
            % E=200e9, nu=0.282, rho=7720
            persistent m
            if isempty(m)
                m = baff.Material(200e9,0.282,7720);
                m.Name = "Stainless400";
            end
            obj = m;
        end
        function obj = Stiff()
            % Static method to create a Stiff material - this a a specif material, which analysis tools may use to define rigid elements
            % E=inf, nu=0, rho=0
            persistent m
            if isempty(m)
                m = baff.Material(inf,0,0);
                m.Name = "Stiff";
            end
            obj = m;
        end
        function obj = Unity()
            % Static method to create a Unity material
            % E=1, nu=-0.5, rho=1
            persistent m
            if isempty(m)
                m = baff.Material(1,-0.5,1);
                m.Name = "Unity";
            end
            obj = m;
        end
    end
end

