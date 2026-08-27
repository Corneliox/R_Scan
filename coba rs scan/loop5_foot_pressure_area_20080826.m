clc; close all; clear all;
open_file='C:\b\rscop_box_pressure\result\3_step_value\data_f_a_p\';
% save_file ='C:\c\f\';
save_file ='C:\d\';


%===========================
%===========================
no_man1=[0:9];
no_man2=[10:17,19:46,50:78];
no_man3=[0:9];
no_man4=[10:17,19:46,50:78];
%===========================
t00_1='_t00'; t00_2='_t0';
LR='L';
for i=1:length(no_man1)
    no_group1(i,:)=[  LR, t00_1, num2str(no_man1(i))   ] ;
end
for i=1:length(no_man2)
    no_group2(i,:)=[  LR , t00_2, num2str(no_man2(i))   ] ;
end
% ++++++++++++++++++++++++++++++++++
LR='R';
for i=1:length(no_man1)
    no_group3(i,:)=[  LR, t00_1, num2str(no_man3(i))   ] ;
end
for i=1:length(no_man2)
    no_group4(i,:)=[ LR , t00_2, num2str(no_man4(i))   ] ;
end
%++++++++++++++++++++++++++++++++++
no_man=[
    no_group1;
    no_group2;
    no_group3;
    no_group4
    ];

% bodyweight_data=load([ open_bodyweight, 'bodyweight75_rsscan.txt']);
% bodyweight_list=([bodyweight_data;bodyweight_data])*9.8;

%==           Pressure Map                      ==

box_color=[
    0.6       0.6        1         %1      toe1
    0       0.7     0         % 2     toe2
    1       0.5     0         % 3==  toe3
    1       1      0      % 4==  toe4-5
    1       0        0         % 5     MT1
    1       0        1         % 6     MT2
    0.5    0.5     0.5      % 7     MT3
    0       0.9     0.9      % 8      MT4-5
    0.5    0        0         %  9== mid_M
    0       1        0         % 10   mid_L
    0.7    0        0.7      % 11    heel_M
    0       0        0.9   ]; % 12   heel_L
% for w=1:length(no_man(:,1))
for w=1
    close all; clc
    w
    num2str(no_man(w,:))
    for i=1:5
        data101_f(:,:,i) =load([ open_file, 'box12_data_101_f12_p12_m1_s1_',num2str(no_man(w,:)),'_', num2str(i),'.txt']);
        data101_a(:,:,i)=load([ open_file, 'data_area_',                                    num2str(no_man(w,:)),'_', num2str(i),'.txt']);
        data101_p(:,:,i)=load([ open_file, 'data_pressure_',                             num2str(no_man(w,:)),'_', num2str(i),'.txt']);
    end

    mean_data_f=mean(data101_f(:,1:12,:),3);
    mean_data_a=mean(data101_a(:,1:12,:),3);
    mean_data_p=mean(data101_p(:,1:12,:),3);

    std_data_f    =   std(data101_f(:,1:12,:),0,3);
    std_data_a   =   std(data101_a(:,1:12,:),0,3);
    std_data_p   =   std(data101_p(:,1:12,:),0,3);

    for i=1:length(mean_data_f(1,:))
        subplot(3,1,1)
        plot([0:1:100],mean_data_f(:,i),'color',box_color(i,:),'linewidth',2); hold on
        plot([0:1:100],[mean_data_f(:,i)+std_data_f(:,i)]   ,'color',box_color(i,:),'linewidth',0.5); hold on
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
end

