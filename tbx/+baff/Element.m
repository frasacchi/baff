classdef Element < matlab.mixin.Heterogeneous & handle
    %Base class which all Baff elements Inherit from
    %   defines common properties and methods for all Baff elements
    %   multple key constructs:
    %       Parent/Children: the parent element defines the origin of the elements location in space
    %       Location: the offset defines the element offset in the parents coordinate system and A the rotaion matrix
    %       Eta: all elementshave a notion of normlised postion, so children can be located at a specific position along the element
    properties
        A = eye(3); % Rotation Matrix
        Offset (3,1)= [0;0;0]; % Offset of the element in the parent element's coordinate system
        isAbsolute = false; %if true, the element is referenced to the global coordinate system, otherwise it is referenced to the parent element
        Eta = 0; %eta coordinate of the element in the parent element's coordinate system
        EtaLength = 0;      % Length of the element in the eta direction
        
        Parent = baff.Element.empty; % Parent element
        Children (1,:) = baff.Element.empty; % Children elements
        
        Name string = "Default Component";    % Name of the element       
        Index = 0;          % Unique index for each element (for use in HDF5 files to link parents and children)

        Meta struct = struct; % Meta data for the element
    end
    properties (Dependent)
        Type; % Element Type String
    end
    methods
        function val = get.Type(obj)
            val = obj.getType();
        end
        function val = getType(obj)
            val = "Element";
        end
    end
    methods(Static)
        function obj = FromBaff(filepath,loc)
            %FromBaff Create an Element from a Baff HDF5 file
            % placeholder for subclasses to overload
            %
            %Args:
            %   filepath (string): Path to the Baff HDF5 file
            %   loc (string): Location in the HDF5 file
            %
            %Returns:
            %   Element
            error('NotImplemented')
        end
    end
    methods(Sealed)
        function val = GetMass(obj,opts)
            %GetMass Get the mass of the element
            %
            %Args:
            %   opts.IncludeChildren (logical, optional, default=true): Include elements children in mass estimation
            %
            %Returns:
            %   Mass of the element
            arguments
                obj
                opts.IncludeChildren = true; % Include children in the mass estimation
            end
            val = zeros(size(obj));
            for i = 1:length(obj)
                val(i) = obj(i).GetElementMass();
                if opts.IncludeChildren
                    optsCell = namedargs2cell(opts);
                    val(i) = val(i) + sum(obj(i).Children.GetMass(optsCell{:}));
                end
            end
        end        
    end
    % operator overloading
    methods
        function val = ne(obj1,obj2)
            %overloads the ~= operator
            val = ~(obj1.eq(obj2));
        end
        function val = eq(obj1,obj2)
            %overloads the == operator
            if length(obj1)~= length(obj2) || ~isa(obj2,'baff.Element')
                val = false;
                return
            end
            val = true;
            for i = 1:length(obj1)
                val = val && all(obj1(i).A == obj2(i).A,'all');
                val = val && all(obj1(i).Offset == obj2(i).Offset,'all');
                val = val && obj1(i).isAbsolute == obj2(i).isAbsolute;
                val = val && obj1(i).Eta == obj2(i).Eta;
                val = val && obj1(i).EtaLength == obj2(i).EtaLength;
                val = val && obj1(i).Children == obj2(i).Children;
                % dont check index as its only there to facitliate read/write...
                % dont check name to be able to see if the actual element
                % is the same
            end
        end
    end
    methods
        function Area = WettedArea(obj)
            %Returns the wetted area of the object (Default 0)
            Area = zeros(size(obj));      
        end
        function val = GetElementMass(obj)
            %Returns the mass of the object (Default 0)
            val = zeros(size(obj));
        end
        function val = GetElementOEM(obj)
            %Returns Operational Empty Mass, e.g. the mass if fuel and payload are have zero filling
            val = GetElementMass(obj);
        end
        function [Xs,masses] = GetElementCoM(obj)
            %Returns Centre of mass and associated mass
            %
            %Returns:
            %   Xs (numeric array): Location of CoM - default zeros.
            %   masses (numeric array): Mass of each object.
            Xs = zeros(3,length(obj));
            masses = zeros(1,length(obj));
        end
        function [X,mass] = GetGlobalCoM(obj)
            %Returns Centre of mass and associated mass
            %
            %Returns: 
            %   Xs (double): Location of CoM - default zeros.
            %   masses (double): Mass of each object.
            [X,mass] = obj.GetCoM();
            X = obj.GetGlobalPos(0,X);
        end
        function [X,mass] = GetCoM(obj)
            if length(obj)>1
                error('Currently only works on scalar calls')
            end
%             Xs = zeros(3,length(obj));
            [X,mass] = obj.GetElementCoM();
            if ~isempty(obj.Children)
                CoM = X.*mass;
                childEtas = [obj.Children.Eta];
                childPos = obj.GetPos(childEtas) + [obj.Children.Offset];
                for i = 1:length(obj.Children)
                    tmpObj = obj.Children(i);
                    [tmpX,tmpM] = tmpObj.GetCoM();
                    if any(isnan([tmpX;tmpM]))
                        error('NaN found')
                    end
                    tmpX = tmpObj.A * tmpX;
                    tmpX = tmpX + repmat(childPos(:,i),1,length(tmpM));
                    mass = mass + sum(tmpM);
                    CoM = CoM + sum(tmpX.*repmat(tmpM,3,1),2);
                    % Xs = [Xs,tmpX];
                    % masses = [masses,tmpM];
                end
                % mass = sum(masses);
                if mass ~= 0
                    % X = mean(Xs,2);
                % else
                    X = CoM./mass;
                end
            end
            if any(isnan(X))
                error('NaN pos found')
            end
        end
    end
    methods
        function obj = Element(opts)
            %Constructor for Element
            %
            %Args:
            %   opts.Offset (double,Default=[0;0;0]): Offset from Parent
            %   opts.eta (double,Default=0): eta coordinate of the element in Parent's coordinate system
            %   opts.Name (string,Default=''): Name of the element
            %   opts.A (double,Default=eye(3)): Rotation Matrix From Parent
            %   opts.EtaLength (double,Default=1): Length of the element in eta direction
            arguments
                opts.Offset = [0;0;0];
                opts.eta = 0;
                opts.Name = ''
                opts.A = eye(3);
                opts.EtaLength = 1;
            end
            obj.Eta = opts.eta;
            obj.Offset = opts.Offset;
            obj.A = opts.A;
            if ~isempty(opts.Name)
                obj.Name = opts.Name;
            end
            obj.EtaLength = opts.EtaLength;
        end
        function obj = add(obj,childObj)
            %Adds a child object
            %
            %Args:
            %   childObj (Element): Child object
            arguments
                obj
                childObj (1,:)
            end
            [childObj.Parent] = deal(obj);
            obj.Children = [obj.Children,childObj];
        end
        function X = GetPos(obj,eta)
            %Returns the position of the object at eta (Default: [0;0;0])
            X = [0;0;0];
        end
        function X = GetGlobalPos(obj,Eta,Offset)
            %Returns the global position of the object
            %
            %Args:
            %   Eta (double): normalised position along element
            %   Offset (double): Offset in element frame of reference (Default [0;0;0])
            arguments
                obj
                Eta
                Offset = [0;0;0];
            end
            X =  obj.Offset + obj.A * (obj.GetPos(Eta) + Offset);
            if ~isempty(obj.Parent)
                X = obj.Parent.GetGlobalPos(obj.Eta,X);
            end
        end
        function A = GetGlobalA(obj)
            %Returns the global rotation matrix
            %
            %Returns:
            %   A (double): Global rotation matrix
            A = obj.A;
            if ~isempty(obj.Parent)
                A = obj.Parent.GetGlobalA() * A;
            end
        end
        function plt_obj = draw(obj,opts)
            %Draws the object
            %
            %Args:
            %   opts.Origin (double): Origin of object in global frame
            %   opts.A (3,3 double): global Rotaion Matrix
            %   opts.Type (string, Default="stick"): plot type {mustBeMember(opts.Type,["stick","surf","mesh"])}
            %
            %Returns:
            %   plt_obj: plot object
            arguments
                obj
                opts.Origin (3,1) double = [0,0,0];
                opts.A (3,3) double = eye(3);
                opts.Type string {mustBeMember(opts.Type,["stick","surf","mesh"])} = "stick";
            end
            plt_obj= [];
            Origin = opts.Origin + opts.A*obj.Offset;
            Rot = opts.A*obj.A;
            for i =  1:length(obj.Children)
                if obj.Children(i).isAbsolute
                    obj.Children(i).draw(Origin=Origin,A=Rot);
                else
                    eta_vector = obj.GetPos(obj.Children(i).Eta);
                    tmp_obj = obj.Children(i).draw(Origin=(Origin+Rot*eta_vector),A=Rot,Type=opts.Type);
                    plt_obj = [plt_obj,tmp_obj];
                end
            end
        end
        function BaffToProp(obj,filepath,loc)
            offs = h5read(filepath,sprintf('%s/Offset',loc));
            etas = h5read(filepath,sprintf('%s/Eta',loc));
            As = h5read(filepath,sprintf('%s/A',loc));
            Names = h5read(filepath,sprintf('%s/Name',loc));
            etaLengths = h5read(filepath,sprintf('%s/EtaLength',loc));
            Indexs = h5read(filepath,sprintf('%s/Index',loc));
            Metas = h5read(filepath,sprintf('%s/Meta',loc));
            for i = 1:length(obj)
                obj(i).Offset = offs(:,i);
                obj(i).Eta = etas(i);
                obj(i).A = reshape(As(:,i),3,3);
                obj(i).Name = Names(i);
                obj(i).EtaLength = etaLengths(i);
                obj(i).Index = Indexs(i);
                obj(i).Meta = jsondecode(Metas(i));
            end
        end
        function ToBaff(obj,filepath,loc)
            %Write the object to a Baff HDF5 file
            %
            %Args:
            %   filepath (string): Path to file
            %   loc (string): Location in file
            N = length(obj);
            h5writeatt(filepath,[loc,'/'],'Qty', N);
            if N ~= 0
                %fill easy data
                h5write(filepath,sprintf('%s/Offset',loc),[obj.Offset],[1 1],[3 N]);
                h5write(filepath,sprintf('%s/Eta',loc),[obj.Eta],[1 1],[1 N]);
                h5write(filepath,sprintf('%s/A',loc),reshape([obj.A],9,[]),[1 1],[9 N]);
                h5write(filepath,sprintf('%s/Name',loc),[obj.Name],[1 1],[1 N]);
                h5write(filepath,sprintf('%s/EtaLength',loc),[obj.EtaLength],[1 1],[1 N]);
                h5write(filepath,sprintf('%s/Index',loc),[obj.Index],[1 1],[1 N]);
                h5write(filepath,sprintf('%s/Meta',loc),arrayfun(@(x)string(jsonencode(x.Meta)),obj).',[1 1],[1 N]);
                pIdx = zeros(1,N);
                for i = 1:N
                    if ~isempty(obj(i).Parent)
                        pIdx(i) = obj(i).Parent.Index;
                    end
                end
                h5write(filepath,sprintf('%s/Parent',loc),pIdx,[1 1],[1 N]);
                %deal with children
                maxChildren = max(arrayfun(@(x)length(x.Children),obj));
                if maxChildren == 0
                    h5write(filepath,sprintf('%s/Children',loc),zeros(1,N),[1,1],[1 N]);
                else
                    child_idx = zeros(maxChildren,N);
                    for i = 1:length(obj)
                        nc = length(obj(i).Children);
                        child_idx(1:nc,i) = arrayfun(@(x)x.Index,obj(i).Children);
                    end
                    h5write(filepath,sprintf('%s/Children',loc),child_idx,[1,1],[maxChildren N]);
                end
            end
        end
    end
    methods(Sealed)
        function LinkElements(obj,filepath,loc,linker)
            %LinkElements Link the elements to their parents and children
            if ~isempty(obj)
                pIdx = h5read(filepath,sprintf('%s/Parent',loc));
                cIdx = h5read(filepath,sprintf('%s/Children',loc));
                cIdx = cIdx(~isnan(cIdx(:,1)),:);
                for i = 1:length(obj)
                    if pIdx(i) > 0
                        obj(i).Parent = linker(i);
                    end
                    for j = 1:size(cIdx,1)
                        if cIdx(j,i)>0
                            obj(i).Children(end+1) = linker(cIdx(j,i));
                        end
                    end
                end
            end
        end
    end
    methods(Static)
        function TemplateHdf5(filepath,loc)
            %TemplateHdf5 Create a template HDF5 file
            %
            %Args:
            %   filepath (string): Path to file
            %   loc (string): Location in file
            h5create(filepath,sprintf('%s/Offset',loc),[3 inf],"Chunksize",[3,10]);
            h5create(filepath,sprintf('%s/Eta',loc),[1 inf],"Chunksize",[1,10]);
            h5create(filepath,sprintf('%s/A',loc),[9 inf],"Chunksize",[9,10]);
            h5create(filepath,sprintf('%s/Name',loc),[1 inf],"Chunksize",[1,10],Datatype="string");
            h5create(filepath,sprintf('%s/EtaLength',loc),[1 inf],"Chunksize",[1,10]);
            h5create(filepath,sprintf('%s/Index',loc),[1 inf],"Chunksize",[1,10]);
            h5create(filepath,sprintf('%s/Parent',loc),[1 inf],"Chunksize",[1,10],"Fillvalue",nan);
            h5create(filepath,sprintf('%s/Children',loc),[256 inf],"Chunksize",[256,10],"Fillvalue",nan);
            h5create(filepath,sprintf('%s/Meta',loc),[1 inf],"Chunksize",[1,10],Datatype="string");
            h5writeatt(filepath,[loc,'/'],'Qty', 0);
        end
    end
end

