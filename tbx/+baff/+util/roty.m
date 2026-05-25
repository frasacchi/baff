function R = roty(angle_deg)
%ROTY Rotation matrix about Y-axis.
%   R = roty(angle_deg) returns a 3x3 rotation matrix for a right-handed
%   rotation of angle_deg degrees about the Y-axis.
a = deg2rad(angle_deg);
R = [ cos(a) 0 sin(a);
      0      1 0;
     -sin(a) 0 cos(a)];
end
