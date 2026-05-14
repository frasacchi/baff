function out = SetStructDMIG(val, N)
    % Return immediately if no DMI couplings are defined
    if isempty(val)
        out = val;
        return;
    end
    
    numCouplings = length(val);
    out = repmat(val(:), 1, N);
    
    for c = 1:numCouplings
        % TODO - Setup to handle multiple couplings per station, currently only symmetric coupling is implemented
        A0 = val(c).A0;
        % B0 = val(c).B0;
        ifo = val(c).IFO;
        
        for i = 1:N
            if ifo == 6 && N > 1
                out(c, i).idx0 = i;
                if i == 1
                    % out(c, i).idx = [i+1];
                    % out(c, i).A = [-A0];
                    out(c, i).idx = [i, i+1];
                    out(c, i).A = [A0, -A0];

                    % out(c, i).B = [B0, -B0];
                elseif i == N
                    % out(c, i).idx = [i-1];
                    % out(c, i).A = [-A0];
                    out(c, i).idx = [i-1, i];
                    out(c, i).A = [-A0, A0];

                    % out(c, i).B = [-B0, B0];
                else
                    % out(c, i).idx = [i-1, i+1];
                    % out(c, i).A = [-A0, -A0];
                    out(c, i).idx = [i-1, i, i+1];
                    out(c, i).A = [-A0, 2*A0, -A0];

                    % out(c, i).B = [-B0, 2*B0, -B0];
                end
            else

                % TODO - NON SYMMETRUIC COUPLINGS - need to define a convention for how the K values are ordered in the input struct for these cases. For now, just assign the same K value to each station.

                out(c, i).idx = i;
                % Handle scalar vs. array inputs for non-stiffness terms
                if isscalar(A0)
                    out(c, i).A = A0;
                elseif length(A0) >= N
                    out(c, i).A = A0(i);
                end
            end
        end
    end
end


