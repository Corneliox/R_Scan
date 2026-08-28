function [aaaa, abcd_in] = func_abcd_in(matrix_one, matrix_list, a, b, c, d)
% FUNC_ABCD_IN - Determines matrix grid points and values inside quad polygon (a,b,c,d)
%
% Inputs:
%   matrix_one  - 2D pressure matrix for a single frame
%   matrix_list - [col, row] coordinates table of all matrix grid points
%   a, b, c, d  - 2-element vertices of the bounding box
%
% Outputs:
%   aaaa        - Nx2 matrix of [x, y] coordinates inside the quad (returns 0x2 if empty)
%   abcd_in     - 1xN vector of pressure values for points inside (returns [] if empty)

% Vertices
x_ab = [a(1), b(1)]; y_ab = [a(2), b(2)];
x_bc = [b(1), c(1)]; y_bc = [b(2), c(2)];
x_cd = [c(1), d(1)]; y_cd = [c(2), d(2)];
x_da = [d(1), a(1)]; y_da = [d(2), a(2)];

% Robust polygon inclusion using inpolygon as primary/ground-truth
poly_x = [a(1), b(1), c(1), d(1), a(1)];
poly_y = [a(2), b(2), c(2), d(2), a(2)];

in_mask = inpolygon(matrix_list(:, 1), matrix_list(:, 2), poly_x, poly_y);

if any(in_mask)
    aaaa = matrix_list(in_mask, :);
else
    % Fallback to linear boundary inequality checks
    try
        ploy_ab = polyfit(x_ab, y_ab, 1);
        ploy_bc = polyfit(x_bc, y_bc, 1);
        ploy_cd = polyfit(x_cd, y_cd, 1);
        ploy_da = polyfit(x_da, y_da, 1);
        
        yy_ab = ploy_ab(1) * matrix_list(:, 1) + ploy_ab(2);
        yy_cd = ploy_cd(1) * matrix_list(:, 1) + ploy_cd(2);
        xx_bc = (matrix_list(:, 2) - ploy_bc(2)) / ploy_bc(1);
        xx_da = (matrix_list(:, 2) - ploy_da(2)) / ploy_da(1);
        
        idx = (yy_ab > matrix_list(:, 2)) & ...
              (xx_bc > matrix_list(:, 1)) & ...
              (yy_cd < matrix_list(:, 2)) & ...
              (xx_da < matrix_list(:, 1));
        
        if any(idx)
            aaaa = matrix_list(idx, :);
        else
            aaaa = zeros(0, 2);
        end
    catch
        aaaa = zeros(0, 2);
    end
end

% Ensure aaaa is strictly Nx2 even when empty
if isempty(aaaa)
    aaaa = zeros(0, 2);
    abcd_in = [];
    return;
end

% Extract pressure values from matrix_one
[n_rows, n_cols] = size(matrix_one);
n_pts = size(aaaa, 1);
abcd_in = zeros(1, n_pts);

for i = 1:n_pts
    col = aaaa(i, 1);
    row = aaaa(i, 2);
    if row >= 1 && row <= n_rows && col >= 1 && col <= n_cols
        abcd_in(i) = matrix_one(row, col);
    else
        abcd_in(i) = 0;
    end
end

end
