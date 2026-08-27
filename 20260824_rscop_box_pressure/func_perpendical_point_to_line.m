function [x_dd,y_dd]=func_perpendical_point_to_line(x_aa,y_aa, x_bb,y_bb,x_cc, y_cc);
x_a=x_aa; y_a=y_aa;
x_b=x_bb; y_b=y_bb;
x_c=x_cc; y_c=y_cc;

% clc; close all; clear all;
% hold on;grid on, axis square;
% axis([-1,5,-1,5])
% set(gca, 'xtick', [-1: 1: 5]);
% set(gca, 'ytick', [-1: 1: 5]);
% 
% x_a=[0,3];  y_a=[1  , 4];
% x_b=[1,5];  y_b=[-1, 1];
% % x_c=[1,2];  y_c=[2  , 3];
% x_c=[1, 2, 1.5];  y_c=[2  , 3, 2.5];
% plot(x_a,y_a,'r-o', x_c,y_c,'ko',x_b,y_b,'m-o' );



ploy_a=polyfit(x_a,y_a,1);
ploy_b=polyfit(x_b,y_b,1);
%=============================
%==  draw 2 times in foot and intersect
%==      (COP Fn & cm(footaxis)) ====
%=============================
for i=1: length(x_c);
    %____________________________________
    %___    x2=-x1+3
    %___    x2= x1+1
    %_          [ 1,1]           [x1] =      [3]
    %_          [-1,1]           [x2] =      [1]
    %_ [function_Fn_Fp] [ pa]=[constant_Fn_Fp]
    %___________________________________
    %== (1) x2= (a) x1 + (b), perpendicular  (a) x2 = (-1) x1 +c
    %==  x2= (-1) x1/ (a)   +  constant_vc
    %==   U.V=x1x2 + y1y2  = a + (-1)a
    %==   x2= (a) x1 + constant_vc

    %===== for i end  key is under here   ====
    constant_vc=ploy_a(1)*y_c(i)   + x_c(i);
    ploy_vc=[-1/ploy_a(1),  constant_vc/ploy_a(1)];
    %==  vc & b  intersect    ==
    function_vc_b  = [-ploy_b(1),1 ;   -ploy_vc(1),1];
    constant_vc_b = [ ploy_b(2);     ploy_vc(2)];
    vc_b=inv( function_vc_b )* constant_vc_b ;
    x_d(i)=vc_b(1);
    y_d(i)=vc_b(2);
end

x_dd=x_d;
y_dd=y_d;
% plot(x_dd, y_dd, 'b^')
% for i=1: length(x_c);
% plot( [x_cc(i),x_dd(i)] , [y_cc(i),y_dd(i)], 'c-')
% end
