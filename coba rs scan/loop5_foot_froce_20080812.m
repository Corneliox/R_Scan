clc; close all; clear all;
open_data101='C:\c\d\data\';
% save_file ='C:\c\f\';
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

%===========================
%===========================
%===========================
% no_man_step=[
%     'R_t000_1'
%     ] ;

%==           Pressure Map                      ==

bodyweight_data=load([ open_bodyweight, 'bodyweight75_rsscan.txt']);
bodyweight_list=([bodyweight_data;bodyweight_data])*9.8;
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
    close all
    w
    num2str(no_man(w,:))
    for i=1:5
        data_101(:,:,i) =load([ open_data101, 'box12_data_101_f12_p12_m1_s1_',  num2str(no_man(w,:)),'_',  num2str(i),'.txt']);
    end

    data_101_mean=mean(data_101,3)/bodyweight_list(w)*100;
    data_101_std=std(data_101,0,3)/bodyweight_list(w)*100;

    mean_data_f        =data_101_mean(:,1:12);
    mean_data_p       =data_101_mean(:,13:24);
    mean_data_matrix=data_101_mean(:,25);
    mean_data_f_sum=data_101_mean(:,26);

    std_data_f        =data_101_std(:,1:12);
    std_data_p       =data_101_std(:,13:24);
    std_data_matrix=data_101_std(:,25);
    std_data_f_sum=data_101_std(:,26);

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
    subplot(3,1,1:2)
    for i=1:length(mean_data_f(1,:))
        plot([0:1:100],mean_data_f(:,i),'color',box_color(i,:),'linewidth',2); hold on
        plot([0:1:100],[mean_data_f(:,i)+std_data_f(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
        plot([0:1:100],[mean_data_f(:,i)-std_data_f(:,i)]    ,'color',box_color(i,:),'linewidth',0.5); hold on
    end
    axis([0 100 0 60]);  grid on;
    % title('total peak presure');
    ylabel('% body weight');

    subplot(3,1,3)
    plot([0:1:100],mean_data_matrix                              ,'k','linewidth',2   ); hold on
    plot([0:1:100],[mean_data_matrix+std_data_matrix],'k','linewidth',0.5); hold on
    plot([0:1:100],[mean_data_matrix-std_data_matrix] ,'k','linewidth',0.5); hold on
    plot([0 100],[100 100],'b-'); hold on

    xlabel('% stance phase');
    ylabel('% body weight');
    axis([0 100 0 130]);   grid on;




    %=================================
    %==                     (Cut)                            ==
    %==        initial time & End time               ==
    %==                                                         ==
    %=================================
    %==      Threshold    (mean 3 sd)             ==
    %=================================
    subplot(3,1,1:2)
    clear start_end_max_peak
    for q=1:length(mean_data_f(1,:))
        fz_cut=mean_data_f(:,q);
        if sum(fz_cut)==0
            start_end_max_peak(q,:)=[0,0,0,0];
        else
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
            plot( [x1-1,  x1-1],    [0,3], 'color', box_color(q,:),'linewidth',2   ); hold on;
            plot( [x2-1,  x2-1],    [0,3], 'color', box_color(q,:),'linewidth',2   ); hold on;

            %==============================
            %==                  Max                           ==
            %==============================
            [max_value, max_index]=max(fz_cut);
            %     plot([0,1:100],fz_cut,'ko-','linewidth',1   ); hold on;
            plot( [max_index-1, max_index-1] ,[max_value,max_value+3] ,'color',box_color(q,:),'linewidth',3   ); hold on; grid on;
            axis([0 100 0 60]);   grid on;

            start_end_max_peak(q,:)=[x1,x2, max_index, max_value];

        end
    end

    %==============================
    %==          force time integral             ==
    %==============================
    data_101_mean_sum=sum(data_101_mean,1);
    %     figure; plot(data_101_mean_sum(1:12), 'ro-')
   %==============================
    
    subplot(3,1,1:2)
    title( ['One plantar foot 12 regions ( ',num2str(no_man(w,:)), ' )  [',num2str(w), ']'      ] );hold on;

%     save([save_file,'box12_data_101_mean_',          num2str(no_man(w,:)),'.txt'],  'data_101_mean'            ,'-ascii')
%     save([save_file,'box12_data_101_std_',              num2str(no_man(w,:)),'.txt'],  'data_101_std'               ,'-ascii')
%     save([save_file,'box12_start_end_max_peak_',  num2str(no_man(w,:)),'.txt'],  'start_end_max_peak'    ,'-ascii')
        save([save_file,'box12_data_101_mean_sum_',  num2str(no_man(w,:)),'.txt'],  'data_101_mean_sum'    ,'-ascii')
 
%     currFig1 = get(0,'CurrentFigure');
%     saveas (currFig1,[save_file,   'box_foot_', num2str(no_man(w,:)) ],'jpg' )
end

