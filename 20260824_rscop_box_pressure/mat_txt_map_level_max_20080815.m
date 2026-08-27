clc; close all; clear all;
open_level='C:\c\b\';
% open_box='C:\b\rscop_box_pressure\txt_step\';
save_file ='C:\d\dd\';

%===========================
%===========================
no_man1=[0:9];
no_man2=[10:17,19:46,50:78];
no_man1=[0:9];
no_man2=[10:17,19:46,50:78];
%===========================
t00_1='_t00'; t00_2='_t0';
LR='L';
for i=1:length(no_man1)
    no_group1(i,:)=[   [num2str(LR)] , [num2str(t00_1)], [num2str(no_man1(i))]   ] ;
end
for i=1:length(no_man2)
    no_group2(i,:)=[   [num2str(LR)] , [num2str(t00_2)], [num2str(no_man2(i))]   ] ;
end
% ++++++++++++++++++++++++++++++++++
LR='R';
for i=1:length(no_man1)
    no_group3(i,:)=[   [num2str(LR)] , [num2str(t00_1)], [num2str(no_man1(i))]   ] ;
end
for i=1:length(no_man2)
    no_group4(i,:)=[   [num2str(LR)] , [num2str(t00_2)], [num2str(no_man2(i))]   ] ;
end
%++++++++++++++++++++++++++++++++++
no_man=[
    no_group1;
    no_group2;
    no_group3;
    no_group4
    ];
for i=1:length(no_man(:,1))
    for j=1:5
        no_man_step(i*5-5+j,:)=[   [num2str(no_man(i,:))] , '_', [num2str(j)]   ];
    end
end
%===========================
% no_man_step=[   'R_t000_1'  ] ;

for w=1:length(no_man_step(:,1))
    % w=1
    clear map_level
    clear map_level_max
    clc
    w
    no_man_step(w,:)
    % load([open_level, 'map_level_max_' ,   [num2str(no_man_step(w,:))],'.mat']);
    load([open_level, 'map_level_' ,   [num2str(no_man_step(w,:))],'.mat']);

    map_level_max=max(map_level,[],3);

    map_level_max;
    save([save_file,'map_level_max_',  num2str(no_man_step(w,:)),'.txt'],  'map_level_max' ,'-ascii')
end

