classdef Model < handle
    %MODEL class to build Baff models
    %   This class is used to create and manage a Baff model, which consists
    %   of various elements such as beams, bluff bodies, constraints, etc.
    %   It provides methods to add elements, draw the model, and save/load
    %   the model to/from a file.
    properties
        Name = ""; % Name of the model
        Beam (:,1) baff.Beam = baff.Beam.empty; % Beam elements
        BluffBody (:,1) baff.BluffBody = baff.BluffBody.empty; % Bluff body elements
        Constraint (:,1) baff.Constraint = baff.Constraint.empty; % Constraint elements
        Hinge (:,1) baff.Hinge = baff.Hinge.empty; % Hinge elements
        Mass (:,1) baff.Mass = baff.Mass.empty; % Mass elements
        Fuel (:,1) baff.Fuel = baff.Fuel.empty; % Fuel elements
        Payload (:,1) baff.Payload = baff.Payload.empty; % Payload elements
        Point (:,1) baff.Point = baff.Point.empty; % Point elements
        Wing (:,1) baff.Wing = baff.Wing.empty; % Wing elements
        Orphans (:,1) baff.Element = baff.Element.empty; % Orphan elements
    end
    methods(Access=private)
        function AddChild(obj,ele)
            %Add children elements to the model
            if isa(ele,'baff.Element')
                obj.(ele.Type)(end+1) = ele;
            end
            % add its Children
            for cIdx = 1:length(ele.Children)
                obj.AddChild(ele.Children(cIdx));
            end
        end
    end
    methods
        function val = ne(obj1,obj2)
            %overloads the ~= operator to check the inequality of two Model objects.
            val = ~(obj1.eq(obj2));
        end
        function val = eq(obj1,obj2)
            %overloads the == operator to check the equality of two Model objects.
            if length(obj1)>1 || length(obj1)~=length(obj2) || ~isa(obj2,'baff.Model')
                val = false;
                return
            end
            val = true;
            val = val && obj1.Orphans == obj2.Orphans;
        end
        function new = Rebuild(obj)
            %rebuild the model by working through the Orphans and populating the array of elements
            %This is useful when the model has been modified and needs to be updated.
            new = baff.Model();
            new.Name = obj.Name;
            for i = 1:length(obj.Orphans)
                new.AddElement(obj.Orphans(i));
            end
        end
        function AddElement(obj,ele)
            %add an element to the model
            if isa(ele,'baff.Element')
                obj.(ele.Type)(end+1) = ele;
            end
            if ~isempty(ele.Parent)
                error('Can only add Orphan Elements directly to the model. Please add the Parent Element to the model.');
            end
            % add its Children
            for cIdx = 1:length(ele.Children)
                obj.AddChild(ele.Children(cIdx));
            end
            % add to the list of Ophans
            obj.Orphans(end+1) = ele;
        end
        function draw(obj,fig_handle,opts)
            %Draw draw an element in 3D Space
            %Args:
            %   fig_handle: handle to the figure to draw in
            %   opts.Type: plot type, can be 'stick', 'surf', or 'mesh'
            arguments
                obj
                fig_handle = figure;
                opts.Type string {mustBeMember(opts.Type,["stick","surf","mesh"])} = "stick";
                opts.A = eye(3);
            end
            hold on
            
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
            %draw the elements
            plt_obj = [];
            for i = 1:length(obj.Orphans)
                p = obj.Orphans(i).draw(Type=opts.Type,A=opts.A);
                plt_obj = [plt_obj,p];
            end
            if isa(fig_handle,'matlab.ui.Figure')
                UserData.obj = obj;
                fig_handle.UserData = UserData;
                set(fig_handle, 'WindowButtonDownFcn',    @baff.util.plotting.BtnDwnCallback, ...
                      'WindowScrollWheelFcn',   @baff.util.plotting.ScrollWheelCallback, ...
                      'KeyPressFcn',            @baff.util.plotting.KeyPressCallback, ...
                      'WindowButtonUpFcn',      @baff.util.plotting.BtnUpCallback)
                [names,idx] = unique(arrayfun(@(x)string(x.Tag),plt_obj));
                lg = legend(plt_obj(idx),names,'ItemHitFcn', @baff.util.plotting.cbToggleVisible);
            end
        end

        function UpdateIdx(obj)
            names = fieldnames(obj);
            idx = 1;
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    for j =1:length(obj.(names{i}))
                        obj.(names{i})(j).Index = idx;
                        idx=idx+1;
                    end
                end
            end
        end

        function ToBaff(obj,filename)
            %TOBAFF save the model to a Baff HDF5 file
            date = datestr(now);
            h5write(filename,'/Version',string(baff.util.get_version));
            h5writeatt(filename,'/','BaffVersion', string(baff.util.get_version));
            h5writeatt(filename,'/','MatlabVersion', version);
            h5writeatt(filename,'/','Created', date);
            h5writeatt(filename,'/','Author', getenv('username'));
            h5writeatt(filename,'/','Computer', getenv('computername'));

            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    obj.(names{i}).ToBaff(filename,sprintf('/BAFF/%s',names{i}));
                end
            end
        end
        function val = GetMass(obj)
            %GetMass get the total mass of the model
            val = 0;
            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    tmp = obj.(names{i});
                    for j = 1:length(tmp)
                        val = val + tmp(j).GetElementMass();
                    end
                end
            end
        end
        function val = GetOEM(obj)
            %GetOEM get the total operational empty mass of the model
            %This is the mass of the model excluding fuel and payload.
            val = 0;
            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    tmp = obj.(names{i});
                    for j = 1:length(tmp)
                        val = val + tmp(j).GetElementOEM();
                    end
                end
            end
        end
        function [X,mass] = GetCoM(obj)
            %GetCoM get the center of mass of the model
            masses = [0];
            Xs = [0;0;0];
            for i = 1:length(obj.Orphans)
                [tmpX,tmpM] = obj.Orphans(i).GetCoM();
                tmpX = obj.Orphans(i).A' * tmpX;
                tmpX = tmpX + repmat(obj.Orphans(i).Offset,1,length(tmpM)) + obj.Orphans(i).Offset;
                Xs = [Xs,tmpX];
                masses = [masses,tmpM];
            end
            masses = masses(2:end);
            Xs = Xs(:,2:end);
            mass = sum(masses);
            X = sum(Xs.*repmat(masses,3,1),2)./mass;
        end


        function AssignChildren(obj,filename)
            %AssignChildren assigns the children of the elements in the model
            %This function is for reading HDF5 models. as after all elemetns are created it links parents to their children etc...
            %Args:
            %   filename: path to the HDF5 file
            linker = baff.Element.empty;
            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    for j =1:length(obj.(names{i}))
                        linker(obj.(names{i})(j).Index) = obj.(names{i})(j);
                    end
                end
            end
            % populate parents and children
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans') && ~isempty(obj.(names{i}))
                    obj.(names{i}).LinkElements(filename,sprintf('/BAFF/%s',names{i}),linker);
                    %populate orphans
                    for j = 1:length(obj.(names{i}))
                        if isempty(obj.(names{i})(j).Parent)
                            obj.Orphans(end+1) = obj.(names{i})(j);
                        end
                    end
                end
            end
        end
    end
    methods(Static)
        function GenTempHdf5(filename)
            %GenTempHdf5 generate a template HDF5 file for the model
            %Args:
            %   filename: path to the HDF5 file
            obj = baff.Model();
            h5create(filename,'/Version',[1 1],'Datatype','string');
            h5write(filename,'/Version',string(baff.util.get_version));
            h5writeatt(filename,'/','BaffVersion', string(baff.util.get_version));
            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    baff.(names{i}).TemplateHdf5(filename,sprintf('/BAFF/%s',names{i}));
                end
            end
        end
        function obj = FromBaff(filename)
            %FromBaff load a Baff model from an HDF5 file
            %Args:
            %   filename: path to the HDF5 file
            obj = baff.Model();
            names = fieldnames(obj);
            for i = 1:length(names)
                if isa(obj.(names{i}),'baff.Element') && ~strcmp(names{i},'Orphans')
                    obj.(names{i}) = baff.(names{i}).FromBaff(filename,sprintf('/BAFF/%s',names{i}));
                end
            end
            obj.AssignChildren(filename);
        end
    end
end

