function R = rotx(angle_deg)
%ROTX Rotation matrix about X-axis.
%   R = rotx(angle_deg) returns a 3x3 rotation matrix for a right-handed
%   rotation of angle_deg degrees about the X-axis.
a = deg2rad(angle_deg);
R = [1  0       0;
     0  cos(a) -sin(a);
     0  sin(a)  cos(a)];
end
