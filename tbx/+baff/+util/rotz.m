function R = rotz(angle_deg)
%ROTZ Rotation matrix about Z-axis.
%   R = rotz(angle_deg) returns a 3x3 rotation matrix for a right-handed
%   rotation of angle_deg degrees about the Z-axis.
a = deg2rad(angle_deg);
R = [cos(a) -sin(a) 0;
     sin(a)  cos(a) 0;
     0       0      1];
end
