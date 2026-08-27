clc; close all; clear all;
open_file='C:\b\rscop_apml\step_txt\';
open_level='C:\c\dd\';
open_box='C:\c\c\';
open_data101='C:\c\d\data\';
save_file ='C:\c\e\';
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
%     'R_t000_1'
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


% for w=1:length(no_man_step(:,1))
for w=1:5;
    close all
 
    %===============================
    %==                                                       ==
    %==           Pressure Map                      ==
    %==                                                       ==
    %===============================
    %==  plot =presure value is square and multiply 10  ===
    %==  that will enhance the readability   ===
    % map_level_max=load([  open_level, 'map_level_max_'       ,num2str(no_man_step(w,:)),'.txt']);
    map_raw    =load([ open_file        , 'map_raw_',                                     [num2str(no_man_step(w,:))],'.txt']);
    xy_cop_i100=load([ open_file       , 'xy_cop_i100_3_' ,                             [num2str(no_man_step(w,:))],'.txt']);
    xy_box        =load([ open_box      , 'xy_box12_' ,                                    [num2str(no_man_step(w,:))],'.txt']);
    data_101     =load([ open_data101, 'box12_data_101_f12_p12_m1_s1_' ,[num2str(no_man_step(w,:))],'.txt']);
    data_f         =data_101(:,1:12)/bodyweight_list(w)*100;;

    level_1=90;  level_2=70;  level_3=69;level_4=68;
    subplot(1,2,1);
    % map=sqrt(map_level_max);
    surf(map_raw);hold on;
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
        subplot(1,2,2)
        plot([0:1:100],data_f(:,i),'color',box_color(i,:),'linewidth',1); hold on
    end
    %===============================
    %===============================
    %===============================

    %=================================
    %==                     (Cut)                            ==
    %==        initial time & End time               ==
    %==                                                         ==
    %=================================
    %==      Threshold    (mean 3 sd)             ==
    %=================================
    subplot(1,2,2)
    clear start_end_max_peak
    for q=1:length(data_f(1,:))
        %     q=8;
        fz_cut=data_f(:,q);
        %     noise_sd=3;
        noise_extend=0;
        %     noise_fz=mean(fz_cut(1:20),1)+noise_sd*std(fz_cut(1:20),0,1);
        noise_fz=0;
        %     subplot(2,1,1); plot([0,100],[noise_fz,noise_fz],'k');

        fz_signal_o=find (fz_cut  >  noise_fz  );
        fz_signal=fz_signal_o;
        fz_signal_o_start=1;
        fz_signal_o_end=length(fz_signal_o);

        clear a
        for i=1:length (fz_signal_o)-1
            a(i)=fz_signal_o(i+1)-fz_signal_o(i);
        end

        a_no=find(a>1);

        if isempty(a_no)==0
            aaa=sum(a_no<length (fz_signal_o)/2);
            bbb=sum(a_no>length (fz_signal_o)/2);
            if aaa(1) >0
                a_no_fore_no=find(a_no<length (fz_signal_o)/2);
                a_no_fore=a_no(a_no_fore_no);
                fz_signal_o_start=a_no_fore(length(a_no_fore))+1;
            end
            if bbb(1)>0
                a_no_hind_no=find(a_no>length (fz_signal_o)/2);
                a_no_hind=a_no(a_no_hind_no);
                fz_signal_o_end=a_no_hind(1);
            end
            fz_signal=fz_signal_o(fz_signal_o_start : fz_signal_o_end);
        end


        fz =fz_cut( fz_signal(1)-noise_extend :1: fz_signal(  length(fz_signal)  )+noise_extend, :);

        % plot([0:1:100],                          fz_cut ,  'ko-','linewidth',1   ); hold on; grid on;
        %   plot(fz_signal(1)-1,                            0,  'ko','linewidth',2   ); hold on;
        x1=fz_signal(1);
        x2=fz_signal(  length(fz_signal)  );
        plot( [x1-1,  x1-1],    [0,1], 'color', box_color(q,:),'linewidth',2   ); hold on;
        plot( [x2-1,  x2-1],    [0,1], 'color', box_color(q,:),'linewidth',2   ); hold on;

        %==============================
        %==                  Max                           ==
        %==============================
        [max_value, max_index]=max(fz_cut);
        subplot(1,2,2)
        %     plot([0,1:100],fz_cut,'ko-','linewidth',1   ); hold on;
        plot( [max_index-1, max_index-1] ,[max_value,max_value+2] ,'color',box_color(q,:),'linewidth',3   ); hold on; grid on;
        axis([0 100 0 60]);   grid on;
    xlabel('% stance phase');
    ylabel(' % bodyweight');

        start_end_max_peak(q,:)=[x1,x2, max_index, max_value];
    end

    save([save_file,'step_start_end_max_peak_',  num2str(no_man(w,:)),'.txt'],  'start_end_max_peak'    ,'-ascii')
    subplot(1,2,2)
    title( ['Step 12 regions ( ',num2str(no_man(w,:)), ' )  [',num2str(w), ']'      ] );hold on;
    currFig1 = get(0,'CurrentFigure');
    saveas (currFig1,[save_file,   'step_', num2str(no_man(w,:)) ],'jpg' )
end

