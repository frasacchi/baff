classdef (Abstract) Base < handle & matlab.mixin.Copyable

    properties(SetAccess=immutable)
        N = 1;
    end
    properties(SetAccess=protected)
        Eta (1,:) = 0;
    end
    properties
        EtaDir = [1;0;0];
        StationDir = [0;1;0];
    end

    methods
        function set.EtaDir(obj,val)
            if size(val,1)~=3
                error('EtaDir must have 3 rows');
            end
            switch size(val,2)
                case obj.N
                    obj.EtaDir = val;
                case 1
                    obj.EtaDir = repmat(val,1,obj.N);
                otherwise
                    error('Columns of EtaDir must be equal to one of the number of stations')
            end
        end
        function set.StationDir(obj,val)
            if size(val,1)~=3
                error('StationDir must have 3 rows');
            end
            switch size(val,2)
                case obj.N
                    obj.StationDir = val;
                case 1
                    obj.StationDir = repmat(val,1,obj.N);
                otherwise
                    error('Columns of StationDir must be equal to one of the number of stations')
            end
        end
    end

    methods
        function obj = Base(eta)
            arguments
                eta;
            end
            obj.Eta = eta;
            obj.N = length(eta);
        end
    end
    %operator overloading
    methods
        function val = ne(obj1,obj2)
            val = ~(obj1.eq(obj2));
        end
        function obj = and(obj1,obj2)
            obj = [obj1 obj2];
        end
        function obj = plus(obj,val)
            if ~isscalar(val) || ~isnumeric(val)
                error('can only add scalar numeric number to Etas')
            end
            obj.Eta = obj.Eta + val;
        end
        function obj = minus(obj,val)
            if ~isscalar(val) || ~isnumeric(val)
                error('can only minus scalar numeric number to Etas')
            end
            obj.Eta = obj.Eta - val;
        end
        function obj = rdivide(obj,val)
            if ~isscalar(val) || ~isnumeric(val)
                error('can only divide Etas by scalar number')
            end
            obj.Eta = obj.Eta ./ val;
        end
        function obj = mtimes(obj,val)
            if ~isscalar(val) || ~isnumeric(val)
                error('can only times Etas by scalar number')
            end
            obj.Eta = obj.Eta .* val;
        end
    end
    methods(Static)
        setDebugMode(enable);
    end
    %other
    methods
        function val = length(obj)
            %overloads the length operator
            val = obj.N;
        end
        function obj = Normalise(obj,NormEta)
            arguments
                obj
                NormEta = obj.Eta(end)
            end
            obj.Eta = (obj.Eta - obj.Eta(1)) / ((NormEta - obj.Eta(1)));
        end
        function [X, Dir] = GetPos(obj, eta)
            % check we have an array of sorted stations
            etas = obj.Eta;
            all_dirs = obj.EtaDir; % Renamed internal var to avoid conflict with output

            if ~issorted(etas)
                error('array of stations must be sorted in ascending order (of eta)')
            end

            % Deal with single length obj (Scalar Object)
            if isscalar(etas)
                X = all_dirs .* (eta - etas(1));
                % Direction is constant
                if isscalar(eta)
                    Dir = all_dirs;
                else
                    Dir = repmat(all_dirs, 1, numel(eta));
                end
                return
            end

            % Calculate positions of the stations (knots)
            delta = [[0;0;0], repmat(etas(2:end)-etas(1:end-1), 3, 1) .* all_dirs(:, 1:end-1)];
            pos = cumsum(delta, 2);

            % Adjust to be zero at zero eta
            if etas(1) ~= 0
                pos = pos - repmat(interp1(etas, pos', 0)', 1, numel(etas));
            end

            % --- Main Interpolation Logic ---
            if isscalar(eta)
                % Scalar Case
                idx = find(etas == eta, 1);
                if ~isempty(idx)
                    X = pos(:,idx);
                    Dir = all_dirs(:, min(idx, size(all_dirs,2)));
                else
                    ii = find(etas>eta,1);
                    if eta<etas(1)
                        delta = (eta-etas(1))/(etas(2)-etas(1));
                        X = pos(:,1) + (pos(:,2)-pos(:,1))*delta;
                        Dir = all_dirs(:,1);
                    elseif eta>etas(end)
                        delta = (eta-etas(end-1))/(etas(end)-etas(end-1));
                        X = pos(:,end-1) + (pos(:,end)-pos(:,1))*delta;
                        Dir = all_dirs(:,end);
                    else
                        delta = (eta-etas(ii-1))/(etas(ii)-etas(ii-1));
                        X = pos(:,ii-1) + (pos(:,ii)-pos(:,ii-1))*delta;
                        Dir = all_dirs(:,ii-1);
                    end
                end
            else
                % Vector Case (Fast Interp)
                bin_idx = discretize(clip(eta, min(etas), max(etas)), etas);

                % Calculate fractional indices directly
                eta_low = etas(bin_idx);
                eta_high = etas(bin_idx + 1);

                alpha = (eta - eta_low) ./ (eta_high - eta_low);
                alpha(eta_high==eta_low) = 0.5; % deal with coincident points
                beta = 1-alpha;
                idx_low = bin_idx;
                idx_high = bin_idx + 1;

                % Interpolate Position
                X = pos(:, idx_low) .* beta + pos(:, idx_high) .* alpha;
                Dir = all_dirs(:, bin_idx);
            end
            % deal with extrapolated etas
            idx = eta<etas(1);
            if nnz(idx)>0
                X(:,idx) = obj.EtaDir(:,1).*(eta(idx)-etas(1)) + repmat(pos(:,1),1,nnz(idx));
                Dir(:,idx) = repmat(all_dirs(:,1),1,nnz(idx));
            end
            idx = eta>etas(end);
            if nnz(idx)>0
                X(:,idx) = obj.EtaDir(:,end).*(eta(idx)-etas(end)) + repmat(pos(:,end),1,nnz(idx));
                Dir(:,idx) = repmat(all_dirs(:,end),1,nnz(idx));
            end
            if any(isnan(X),"all")
                error("unexpected NaN in interpolation of station positions")
            end
        end
        function [lenLocus,kappa] = GetLocus(obj)
            % gets the length of the locus formed by the stations and returns the
            % normalised positon of the stations along the locus
            etas = obj.Eta;
            dirs = obj.EtaDir;
            seg_locus_len = (etas(2:end)-etas(1:end-1)).*vecnorm(dirs(:,1:end-1));
            lenLocus = sum(seg_locus_len);
            kappa = [0,cumsum(seg_locus_len)/lenLocus];
            kappa = round(kappa,12);
        end
        function [etas,idx_low,idx_high,alpha] = InterpolateEtas(obj,N,method,PreserveOld)
            %INTERPOLATEETAS get list of etas to interpolate at
            % interpolates in one of three methods depending
            % on "method":
            % "eta": N is an array of etas to interpolate at
            % "linear": N is a scalar of the number of linear distributed
            % points to interpolate at
            % "cosine": same as linear but with cosine distribution
            %
            % the argument PereserveOld will ensure the original Etas are
            % in the output if set to true (default false)
            arguments
                obj
                N
                method string {mustBeMember(method,["eta","linear","cosine"])} = "eta";
                PreserveOld logical = false;
            end
            old_eta = obj.Eta;
            switch method
                case "eta"
                    if max(N)>old_eta(end) || min(N)<old_eta(1)
                        error("N must be between old_eta(1) and old_eta(end)")
                    end
                    etas = N;
                    N = length(etas);
                case "linear"
                    if N <= 2
                        error("if N is scalar it must be greater than 1.")
                    end
                    etas = linspace(old_eta(1),old_eta(end),N);
                case "cosine"
                    if N <= 2
                        error("if N is scalar it must be greater than 1.")
                    end
                    etas = old_eta(1) + (old_eta(end) - old_eta(1)) * sin(linspace(0,pi/2,N));
            end
            if PreserveOld
                if N < length(old_eta)
                    error("Can't preserve old etas if new points number less than previous number of stations")
                elseif N == length(old_eta)
                    etas = old_eta;
                else
                    idx = nan(1,length(old_eta));
                    idx(1) = 1;
                    for i = 2:length(old_eta)-1
                        [~,ii] = min(abs(etas(2:end-1)-old_eta(i)));
                        ii = ii+1;
                        if ismember(ii,idx)
                            error("can't preserve old etas as 1 of the new etas is closest to 2 of the new etas")
                        end
                        idx(i) = ii;
                    end
                    idx(end) = length(etas);
                    etas(idx) = old_eta;
                end
            end
            % get eta interpolatants
            % Find bin indices
            bin_idx = discretize(etas, old_eta);

            % Calculate fractional indices directly
            eta_low = old_eta(bin_idx);
            eta_high = old_eta(bin_idx + 1);
            alpha = (etas - eta_low) ./ (eta_high - eta_low);

            % Handle constant segments (avoid NaN from 0/0)
            alpha(eta_high == eta_low) = 0;

            % Index arrays for interpolation
            idx_low = bin_idx;
            idx_high = bin_idx + 1;

        end
    end
    methods (Abstract)
        stations = interpolate(obj,etas);
        stations = horzcat(varargin);
        stations = eq(obj1,obj2);
        stations = Duplicate(obj,EtaArray)
    end
end

