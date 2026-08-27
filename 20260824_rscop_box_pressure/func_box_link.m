
function [ x_pick1,y_pick1, x_pick2,y_pick2,  x_pick3,y_pick3]=func_box_link(color_pick,box_no,point_no)

% clc; close all; clear all;
% axis([0 7, 0 7]);set(gca, 'xtick', [0:1: 7], 'ytick', [0:1: 7]);grid on;hold on;
% color_pick='b.';
% box_no=3;
% point_no=4;
for j=1:box_no                                     %__muti-ciclre
    clear x_i; clear y_i;
    [x_i, y_i]=ginput(1);
    plot( x_i, y_i,[color_pick], 'linewidth',1);hold on;
    plot( x_i, y_i,[color_pick], 'linewidth',1);hold on;
    for i=1:point_no-1
        [x_i(i+1), y_i(i+1)]=ginput(1);
        plot( x_i(i+1), y_i(i+1),[color_pick], 'linewidth',1);hold on;
        plot( [x_i(i), x_i(i+1)] , [y_i(i), y_i(i+1)],[color_pick(1),'-'], 'linewidth',1);hold on;
    end
    plot( [x_i(1), x_i(length(x_i))] , [y_i(1), y_i(length(y_i)) ],'r-', 'linewidth',1);hold on;
    eval(['x_pick',num2str(j),'=x_i(1:length(x_i))']);
    eval(['y_pick',num2str(j),'=y_i(1:length(y_i))']);
end
% plot( x_pick1, y_pick1, 'r-^');
% plot( x_pick2, y_pick2, 'r-^');
% plot( x_pick3, y_pick3, 'r-^');