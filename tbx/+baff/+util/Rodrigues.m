function A = Rodrigues(v,angle)
    %RODRIGUES Reurns the rotation matix assiated with the vector omega
    %   omega is a vector whos direction refines the axis of rotation and who
    %   magnitude defines the magnitude of rotation (in radians)
    if angle == 0
        A = repmat(eye(3),1,1,size(v,3));
    else
        n = v./vecnorm(v);
        if size(v,3)==1
            A = eye(3)+ Wedge(n)*sin(angle) + Wedge(n)*Wedge(n)*(1-cos(angle));
        else
            if size(v,3)~=size(angle,3)
                error("pages of v and angle must be of same length")
            end
            A = repmat(eye(3),1,1,size(v,3));
            W = Wedge(n);
            A = A + pagemtimes(W,sin(angle)) + pagemtimes(pagemtimes(W,W),(1-cos(angle)));
        end
    end
    end
    
    function V  = Wedge(v)
    V = zeros(3,3,size(v,3));
    V(1,2,:) = -v(3,1,:);
    V(2,1,:) = v(3,1,:);
    V(3,1,:) = -v(2,1,:);
    V(1,3,:) = v(2,1,:);
    V(2,3,:) = -v(1,1,:);
    V(3,2,:) = v(1,1,:);
    end