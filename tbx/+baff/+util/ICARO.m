function [obj,f] = ICARO(obj,opts)
    %removes wing components from a baff structure based on their names
    arguments
        obj
        opts.remove = '';
    end

    f = false;
    if isempty(opts.remove) || isempty(obj)
        return
    end

    for i = 1:numel(opts.remove)
        if (isa(obj, 'baff.Wing') || isa(obj,'baff.DraggableWing')) && contains(obj.Name,opts.remove{i})
            % obj = []; %remove this component
            % obj = baff.Element.empty;
            f = true;
            return
        end
    end

    %generate obj.Components for Children
    % if ~isempty(obj.Children)
        for i = length(obj.Children):-1:1
                [~,f] = baff.util.ICARO(obj.Children(i),'remove',opts.remove);
                if f
                    obj.Children(i)=[];
                end
        end
    % end
end