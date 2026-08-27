clc; close all; clear all;
open_file='C:\b\rscop_box_pressure\result\5_foot\force_area_pressure\';
% save_file ='C:\c\f\';
save_file ='C:\d\';
open_bodyweight='C:\b\';
plot_sd='y';
plot_sum='y';
plot_stard_end='n';
%===========================
%===========================
% no_man1=[0:9];
% no_man2=[10:17,19:46,50:78];
% no_man3=[0:9];
% no_man4=[10:17,19:46,50:78];
%///////////////////////////////////////////////////////////////////
%///////////////////////////////////////////////////////////////////
%//////////      Arch Index                       /////////
%//////////      t000~t078       0.21~0.26 /////////
%//////////    Just right feet
% cut
% high      serial 4,12,             (subject 17,57)
% normal serial 3                    (subject 7)
% flat         serial 10,12,20,21 (subject 64,67,76,77)
%///////////////////////////////////////////////////////////////////
%///////////////////////////////////////////////////////////////////
%///////////////////////////////////////////////////////////////////
%///////////////////////////////////////////////////////////////////
%//////////      Arch Index                       /////////
%//////////      t000~t078       0.21~0.26 /////////
%//////////    Just right feet
% cut
% high      serial 4,12,             (subject 17,57)
% normal serial 3                    (subject 7)
% flat         serial 10,12,20,21 (subject 64,67,76,77)
%///////////////////////////////////////////////////////////////////
%///////////////////////////////////////////////////////////////////
no_man1=[];no_man2=[];no_man3=[];no_man4=[];
% _______AI <0.21_______________
% ////////////////////////////////////////
% ////////////////////////////////////////
color_group='b:';
color_mark='^';
plot_linewidth=1.5;

if plot_sd=='y'
    color_group='b';
    plot_linewidth=1.5;
end
name_data='Higharch';
no_man3=[1];
no_man4=[12,13,19,22,50,52,53,54,55,58];
% ////////////////////////////////////////
% ////////////////////////////////////////
% _______0.21~AI~ 0.26__________
% ////////////////////////////////////////
% ////////////////////////////////////////
% color_group='k--';
% color_mark='o';
% plot_linewidth=1.5;
% if plot_sd=='y'
%     color_group='k';
%     plot_linewidth=1.5;
% end
% name_data='Normal';
% no_man3=[2,3];
% no_man4=[15,16,21,26,29,32,33,40,41,46];
% ////////////////////////////////////////
% ////////////////////////////////////////
% _______AI>0.26_______________
% ////////////////////////////////////////
% ////////////////////////////////////////
% color_group='r-';
% color_mark='square';
% plot_linewidth=1;
% if plot_sd=='y'
%     color_group='r';
%     color_mark='o';
%     plot_linewidth=1.5;
% end
% name_data='Flatfoot';
% no_man3=[4,5];
% no_man4=[20,23,24,28,31,38,63,65,68,69,70,71,72,73,74];
% ////////////////////////////////////////
% ////////////////////////////////////////

%===========================
t00_1='_t00'; t00_2='_t0';


%===========================
% LR='L';
% for i=1:length(no_man1)
%     no_group1(i,:)=[  LR, t00_1, num2str(no_man1(i))   ] ;
% end
% for i=1:length(no_man2)
%     no_group2(i,:)=[  LR , t00_2, num2str(no_man2(i))   ] ;
% end
% ++++++++++++++++++++++++++++++++++
LR='R';
for i=1:length(no_man3)
    no_group3(i,:)=[  LR, t00_1, num2str(no_man3(i))   ] ;
end
for i=1:length(no_man4)
    no_group4(i,:)=[ LR , t00_2, num2str(no_man4(i))   ] ;
end
%++++++++++++++++++++++++++++++++++
no_man=[
    %     no_group1;
    %     no_group2;
    no_group3;
    no_group4
    ];

%===========================
%===========================
%===========================
%===========================
% no_man_step=[
%     'R_t000_1'
%     ] ;

% bodyweight_data=load([ open_bodyweight, 'bodyweight75_rsscan.txt']);
% bodyweight_list=([bodyweight_data;bodyweight_data])*9.8;

%==           Pressure Map                      ==

bodyweight_data=load([ open_bodyweight, 'bodyweight75_rsscan.txt']);
bodyweight_list=([bodyweight_data;bodyweight_data])*9.8;

for w=1:length(no_man(:,1))
        data101_f(:,:,w) =load([ open_file, 'foot_fap_mean_fN_',          num2str(no_man(w,:)),'.txt']);
        data101_a(:,:,w)=load([ open_file, 'foot_fap_mean_area_',       num2str(no_man(w,:)),'.txt']);
        data101_p(:,:,w)=load([ open_file, 'foot_fap_mean_pressure_',num2str(no_man(w,:)),'.txt']);
end
mean_f=mean(data101_f(:,1:12,:),3);
mean_a=mean(data101_a(:,1:12,:),3);
mean_p=mean(data101_p(:,1:12,:),3);

std_f    =   std(data101_f(:,1:12,:),0,3);
std_a   =   std(data101_a(:,1:12,:),0,3);
std_p   =   std(data101_p(:,1:12,:),0,3);

mean_sum_f=sum(mean_f,2);
mean_sum_a=sum(mean_a,2);
mean_sum_p=sum(mean_p,2);

std_sum_f=sum(std_f,2);
std_sum_a=sum(std_a,2);
std_sum_p=sum(std_p,2);


if plot_sum=='y'
    subplot(2,2,3)
    plot([0:1:100],mean_sum_a,'linewidth',plot_linewidth); hold on
    plot([0,100],[100, 100]  ,'k'); hold on
    if plot_sd=='y'
        plot([0:1:100],[mean_sum_a+std_sum_a] ,color_group,'linewidth',0.5); hold on
        plot([0:1:100],[mean_sum_a-std_sum_a]  ,color_group,'linewidth',0.5); hold on
    end
    xlabel('% stance phase');
    ylabel(' % area');
end

% subplot_no=[
%     4;3;2;1;
%     8;7;6;5;
%     10;9;
%     14;13];

subplot_no=[
    1;2;3;4;
    5;6;7;8;
        11;12;
        15;16];
clear start_end_max_peak
for q=1:length(mean_data_f(1,:))
    % i=1
    eval( ['subplot(4,4,', num2str(subplot_no(q)), ')'   ] );
    plot([0:1:100],mean_data_f(:,q),color_group,'linewidth',plot_linewidth); hold on
    %     ylabel('force (N) ');
    if plot_sd=='y'
        plot([0:1:100],[mean_data_f(:,q)+std_data_f(:,q)] ,color_group,'linewidth',0.5); hold on
        plot([0:1:100],[mean_data_f(:,q)-std_data_f(:,q)]  ,color_group,'linewidth',0.5); hold on
    end

    fz_cut=mean_data_f(:,q);
    %==============================
    %==                  Max                           ==
    %==============================
    [max_value, max_index]=max(fz_cut);
    %     plot([0,1:100],fz_cut,'ko-','linewidth',1   ); hold on;
    plot( max_index-1,max_value ,[num2str(color_group(1)),color_mark],'linewidth',plot_linewidth   ); hold on;
    %     axis([0 100 0 60]); grid on;
 
    %==========================
    %==========================
    group_semp(q,:)=[max_index, max_value];
end


% subplot(4,4,7); xlabel('% stance phase');
% subplot(4,4,8); xlabel('% stance phase');
% subplot(4,4,13); xlabel('% stance phase');
% subplot(4,4,14); xlabel('% stance phase');

% subplot(4,4,2)
% title( ['One plantar foot 12 regions ( ',num2str(no_man(w,:)), ' )  [',num2str(w), ']'      ] );hold on;

group_semp_spss=[box12_start, box12_end,box12_x_max, box12_y_peak];

% save( [save_file, name_data,'_box12_group_semp_spss', '.txt'],  'group_semp_spss'    ,'-ascii')
% save( [save_file, name_data,'_box12_group_semp',          '.txt'],  'group_semp'              ,'-ascii')
% save( [save_file, name_data,'_box12_group_sum_spss',  '.txt'],  'box12_group_sum'    ,'-ascii')
% 
% currFig1 = get(0,'CurrentFigure');
% saveas (currFig1,[save_file,   'box_group',  ],'jpg' )

















for i=1:length(mean_data_f(1,:))
    subplot(3,1,1)
    plot([0:1:100],mean_data_f(:,i),'color',box_color(i,:),'linewidth',2); hold on
    plot([0:1:100],[mean_data_f(:,i)+std_data_f(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    plot([0:1:100],[mean_data_f(:,i)-std_data_f(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    subplot(3,1,2)
    plot([0:1:100],mean_data_a(:,i),'color',box_color(i,:),'linewidth',2); hold on
    plot([0:1:100],[mean_data_a(:,i)+std_data_a(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    plot([0:1:100],[mean_data_a(:,i)-std_data_a(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    subplot(3,1,3)
    plot([0:1:100],mean_data_p(:,i),'color',box_color(i,:),'linewidth',2); hold on
    plot([0:1:100],[mean_data_p(:,i)+std_data_p(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    plot([0:1:100],[mean_data_p(:,i)-std_data_p(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
end

subplot(3,1,1);
axis([0 100 0 400]); ylabel(' focre (N)');    grid on;
title( ['Foot 12 regions: Force, Area, Pressure ( ',num2str(no_man(w,:)), ' )  [',num2str(w), ']' ]);hold on;
subplot(3,1,2);
axis([0 100 0 30]);  ylabel(' area (cm^2)'); grid on;
subplot(3,1,3);
axis([0 100 0 40]);  ylabel(' pressure (N/cm^2)'); xlabel('% stance phase');grid on;

%     save([save_file,'foot_fap_mean_fN_',          num2str(no_man(w,:)),'.txt'], 'mean_data_f'   ,'-ascii')
%     save([save_file,'foot_fap_std_fN_',             num2str(no_man(w,:)),'.txt'], 'std_data_f'      ,'-ascii')
%     save([save_file,'foot_fap_mean_area_',       num2str(no_man(w,:)),'.txt'], 'mean_data_a'  ,'-ascii')
%     save([save_file,'foot_fap_std_area_',          num2str(no_man(w,:)),'.txt'], 'std_data_a'     ,'-ascii')
%     save([save_file,'foot_fap_mean_pressure_',num2str(no_man(w,:)),'.txt'], 'mean_data_p' ,'-ascii')
%     save([save_file,'foot_fap_std_pressure_',    num2str(no_man(w,:)),'.txt'], 'std_data_p'     ,'-ascii')
%
%     currFig1 = get(0,'CurrentFigure');
%     saveas (currFig1,[save_file,   'foot_fap_', num2str(no_man(w,:)) ],'jpg' )


