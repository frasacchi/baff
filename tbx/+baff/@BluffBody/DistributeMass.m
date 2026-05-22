function obj = DistributeMass(obj, mass, Nele,opts)
    %DistributeMass distributes mass along a bluff body element as discrete lumped masses.
    %   This function creates N lumped masses spread across the bluff body with the 
    %   fraction at each point proportional to the normalized volume at each section.
    %   The masses are positioned at the centroid of each section.
    %
    %Args:
    %   obj: BluffBody object to add masses to
    %   mass: Total mass to distribute
    %   Nele: Number of discrete mass elements to create
    %   opts.Offset: Offset vector for mass positions [default: [0;0;0]]
    %   opts.tag: Name tag for mass elements [default: 'body_mass']
    %   opts.IncludeTips: Include tip positions in mass distribution [default: false]
    %   opts.isFuel: Create fuel masses instead of regular masses [default: false]
    %   opts.isPayload: Create payload masses instead of regular masses [default: false]
    %   opts.Etas: Eta range for mass distribution [default: [nan nan] - uses full body]
    %
    %Returns:
    %   obj: Modified BluffBody object with distributed masses added
    arguments
        obj
        mass
        Nele
        opts.Offset = [0;0;0];
        opts.tag = 'body_mass';
        opts.IncludeTips = false;
        opts.isFuel logical = false;
        opts.isPayload logical = false;
        opts.Etas (1,2) double = [nan nan];
    end
    % Set eta limits for mass distribution - use full body range if not specified
    % Set eta limits for mass distribution - use full body range if not specified
    Etas = opts.Etas;
    if isnan(Etas(1))
        Etas(1) = obj.Stations.Eta(1);
    end
    if isnan(Etas(2))
        Etas(2) = obj.Stations.Eta(end);
    end
    if Etas(1)==Etas(2)
        Nele = 1;
        masses = mass;
        etas = Etas(1);
    else
        % Calculate mass distribution based on normalized volumes at each section
        etas = linspace(Etas(1),Etas(2),Nele+1);
        secs = obj.Stations.interpolate(etas);
        NormVols = secs.NormVolumes();
        masses = NormVols./sum(NormVols) * mass;
    
        % Calculate eta positions for mass placement
        if opts.IncludeTips
            % Place masses at equally spaced positions including tips
            etas = linspace(Etas(1),Etas(2),Nele);
        else
            % Place masses at section centroids (avoiding tips)
            etas = linspace(Etas(1),Etas(2),(2*Nele)+1);
            etas = etas(2:2:(end-1));
        end
    end

    % Create the point masses and add them to the bluff body
    for i = 1:Nele
        % Create appropriate mass type based on options
        if opts.isFuel
            tmp_mass = baff.Fuel(masses(i),"eta",etas(i),"Name",sprintf('%s_%.0f',opts.tag,i));
        elseif opts.isPayload
            tmp_mass = baff.Payload(masses(i),"eta",etas(i),"Name",sprintf('%s_%.0f',opts.tag,i));
        else
            tmp_mass = baff.Mass(masses(i),"eta",etas(i),"Name",sprintf('%s_%.0f',opts.tag,i));
        end
        % Apply offset and add mass to the bluff body
        tmp_mass.Offset = opts.Offset;
        obj.add(tmp_mass);
    end

end