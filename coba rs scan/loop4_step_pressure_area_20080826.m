clc; close all; clear all;
open_file='C:\b\rscop_apml\step_txt\';
open_level=             'C:\b\rscop_box_pressure\result\1_step_level\';
open_box=              'C:\b\rscop_box_pressure\result\2_step_get_xy\';
open_data101=       'C:\b\rscop_box_pressure\result\3_step_value\data_f_a_p\';
open_box12_value='C:\b\rscop_box_pressure\result\3_step_value\inbox_value_L\';
save_file ='C:\d\';
open_bodyweight='C:\b\';

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
    no_group3(i,:)=[  LR, t00_1, num2str(no_man1(i))   ] ;
end
for i=1:length(no_man2)
    no_group4(i,:)=[ LR , t00_2, num2str(no_man2(i))   ] ;
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
%===========================
%===========================
%===========================
% no_man_step=[
%     'R_t063'
%     ] ;

bodyweight_data=load([ open_bodyweight, 'bodyweight75_rsscan.txt']);
for j=1:length(bodyweight_data(:,1))
    for i=1:5
        body_5(j*5-5+i, :)=bodyweight_data(j,:) ;
    end
end
bodyweight_list=([body_5;body_5])*9.8;

box_color=[
    0.6    0.6     1         %1      toe1
    0       0.7     0         % 2     toe2
    1       0.5     0         % 3==  toe3
    1       1        0      % 4==  toe4-5
    1       0        0         % 5     MT1
    1       0        1         % 6     MT2
    0.5    0.5     0.5      % 7     MT3
    0       0.9     0.9      % 8      MT4-5
    0.5    0        0         %  9== mid_M
    0       1        0         % 10   mid_L
    0.7    0        0.7      % 11    heel_M
    0       0        0.9   ]; % 12   heel_L


% for w=693:length(no_man_step(:,1))
for w=1;
    clc
    close all
    clear box12_area  data_area  data_pressure
    w
    num2str(no_man_step(w,:))
    %===============================
    %==                                                       ==
    %==           Pressure Map                      ==
    %==                                                       ==
    %===============================
    %==  plot =presure value is square and multiply 10  ===
    %==  that will enhance the readability   ===
    map_level_max=load([  open_level, 'map_level_max_',                            num2str(no_man_step(w,:)),'.txt']);
    %     map_raw     =load([ open_file        , 'map_raw_',                                 num2str(no_man_step(w,:)),'.txt']);
    xy_cop_i100=load([ open_file       , 'xy_cop_i100_3_' ,                             num2str(no_man_step(w,:)),'.txt']);
    xy_box        =load([ open_box      , 'xy_box12_' ,                                    num2str(no_man_step(w,:)),'.txt']);
    data_101     =load([ open_data101, 'box12_data_101_f12_p12_m1_s1_' ,num2str(no_man_step(w,:)),'.txt']);
    data_f_n    =data_101(:,1:12);
    data_f         =data_f_n/bodyweight_list(w)*100;;



    level_1=90;  level_2=70;  level_3=69;level_4=68;
    subplot(1,2,1);
    % map=sqrt(map_level_max);
    surf(map_level_max);hold on;
    x_copi=xy_cop_i100(:,1);
    y_copi=xy_cop_i100(:,2);
    cop_zi=x_copi(:,1).*0+level_1;
    plot3(x_copi, y_copi,cop_zi,'w','linewidth',3 );hold on;
    plot3(x_copi, y_copi,cop_zi,'r.-','linewidth',1 );hold on;
    view(0,90);grid on;  axis equal;hold on;
    box=xy_box;
    box_level_1=[box(1,1:2:8), box(1,1)]*0+level_1;

    for i=1:length(box(:,1))
        subplot(1,2,1)
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,num2str(i),'BackgroundColor',[0,0,0], 'fontsize',13,'HorizontalAlignment','center');
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,num2str(i),'BackgroundColor',box_color(i,:), 'fontsize',11,'HorizontalAlignment','center');
        text( (box(i,1)+box(i,3))/2+1, (box(i,4)+box(i,6))/2, level_1,num2str(i),'BackgroundColor',[1,1,1], 'fontsize',7, 'HorizontalAlignment','center');
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'c-','linewidth',2);hold on;
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'k-','linewidth',1);hold on;
        subplot(3,2,2)
        plot([0:1:100],data_f_n(:,i),'color',box_color(i,:),'linewidth',1); hold on
        %         xlabel('% stance phase');

        %=================================
        %==              count area                          ==
        %=================================
        %_     the sensor size is width ( 5.3 mm) and length ( 7.5 mm)
        %_     the area of total sensors is 339.2 mm x 480.0 mm.
        %_     (1 N/ cm^2 = 10 kPa = 0.1 bar)
        box12_value=load([ open_box12_value, 'box12_value_inbox' ,num2str(i),'_',num2str(no_man_step(w,:)),'.txt']);
        box12_area(:,i)=sum(box12_value>0,  2)*0.53*0.75;

        xi_divide=100;
        y=box12_area(:,i);
        x=(0:(100/(length(y)-1)):100)';
        xi=0:(100/xi_divide):100;
        yi=interp1(x,y,xi,'linear');
        data_area(:,i)=yi;

        subplot(3,2,4)
        plot([0:1:100],data_area(:,i),'color',box_color(i,:),'linewidth',1); hold on


        for j=1:length(data_area(:,i))
            if data_area(j,i)==0
                data_pressure(j,i)=0;
            else
                data_pressure(j,i)=data_f_n(j,i)./data_area(j,i);
            end
        end
        subplot(3,2,6)
        plot([0:1:100],data_pressure(:,i),'color',box_color(i,:),'linewidth',1); hold on

    end
    %===============================
    %===============================
    %===============================
    subplot(1,2,1)
    title( ['Step 12 regions: Force, Area, Pressure ( ',num2str(no_man_step(w,:)), ' )  [',num2str(w), ']'      ] );hold on;
    subplot(3,2,2); ylabel(' focre (N)');
    subplot(3,2,4); ylabel(' area (cm^2)');
    subplot(3,2,6); ylabel(' pressure (N/cm^2)'); xlabel('% stance phase');

    save([save_file,'data_pressure_', num2str(no_man_step(w,:)),'.txt'],  'data_pressure'    ,'-ascii')
    save([save_file,'data_area_',        num2str(no_man_step(w,:)),'.txt'],  'data_area'    ,'-ascii')

    currFig1 = get(0,'CurrentFigure');
    saveas (currFig1,[save_file,   'step_pressure_area_', num2str(no_man_step(w,:)) ],'jpg' )
end

