function [x_dd, y_dd] = func_perpendical_point_to_line(x_aa, y_aa, x_bb, y_bb, x_cc, y_cc)
% FUNC_PERPENDICAL_POINT_TO_LINE - Computes intersection on line B perpendicular to line A
%
% Line A defined by points (x_aa, y_aa)
% Line B defined by points (x_bb, y_bb)
% Reference points C: (x_cc, y_cc)

x_d = zeros(1, length(x_cc));
y_d = zeros(1, length(x_cc));

% Vector representation of Line A and Line B
v_a = [x_aa(2) - x_aa(1), y_aa(2) - y_aa(1)];
v_b = [x_bb(2) - x_bb(1), y_bb(2) - y_bb(1)];

% Normal to line A (perpendicular direction)
n_a = [-v_a(2), v_a(1)];
if norm(n_a) > 0
    n_a = n_a / norm(n_a);
else
    n_a = [0, 1];
end

for i = 1:length(x_cc)
    c_pt = [x_cc(i), y_cc(i)];
    b1   = [x_bb(1), y_bb(1)];
    
    % Linear system: b1 + s * v_b = c_pt + t * n_a
    % [v_b(1), -n_a(1); v_b(2), -n_a(2)] * [s; t] = [c_pt(1) - b1(1); c_pt(2) - b1(2)]
    M = [v_b(1), -n_a(1); v_b(2), -n_a(2)];
    rhs = [c_pt(1) - b1(1); c_pt(2) - b1(2)];
    
    if abs(det(M)) > 1e-12
        st = M \ rhs;
        pt_d = b1 + st(1) * v_b;
    else
        % Fallback projection of point C onto line B
        if norm(v_b) > 0
            u_b = v_b / norm(v_b);
            s_proj = dot(c_pt - b1, u_b);
            pt_d = b1 + s_proj * u_b;
        else
            pt_d = b1;
        end
    end
    
    x_d(i) = pt_d(1);
    y_d(i) = pt_d(2);
end

x_dd = x_d;
y_dd = y_d;

end
