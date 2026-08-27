clc; clear all;
% close all;
open_mean='C:\b\rscop_box_pressure\result\5_foot\start_end\';
% save_file ='C:\c\g\';
save_file ='C:\d\';
open_bodyweight='C:\b\';
plot_sd='y';
plot_grf='y';
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




clear data_101_mean_group data_box12_semp...
    box12_start box12_end box12_x_max box12_y_peak
for w=1:length(no_man(:,1));
    %     for w=76:150;
    % w=1
    %===============================
    %==                                                       ==
    %==           Pressure Map                      ==
    %==                                                       ==
    %===============================
    %==  plot =presure value is square and multiply 10  ===
    %==  that will enhance the readability   ===
    data_101_mean_group(:,:,w)=load([ open_mean,'box12_data_101_mean_',num2str(no_man(w,:)),'.txt']);
    data_box12_semp(:,:,w)       =load([ open_mean,'box12_start_end_max_peak_',num2str(no_man(w,:)),'.txt']);
    box12_group_sum(:,:,w)        = load([ open_mean,'box12_data_101_mean_sum_',num2str(no_man(w,:)),'.txt']);
  
    box12_start(w,:)=data_box12_semp(:,1,w)'-1;
    box12_end(w,:)=data_box12_semp(:,2,w)'-1;
    box12_x_max(w,:)=data_box12_semp(:,3,w)'-1;
    box12_y_peak(w,:)=data_box12_semp(:,4,w)';
end


data_101_mean=mean(data_101_mean_group,3);
data_101_std=std(data_101_mean_group,0,3);
mean_data_f=data_101_mean(:,1:12);
std_data_f=data_101_std(:,1:12);

mean_data_matrix=data_101_mean(:,25);
std_data_matrix=data_101_std(:,25);

mean_data_f_sum=data_101_mean(:,26);

if plot_grf=='y'
    subplot(2,2,3)
    plot([0:1:100],mean_data_matrix,color_group,'linewidth',plot_linewidth); hold on
    % plot([0:1:100],mean_data_f_sum,color_group,'linewidth',1); hold on
    plot([0,100],[100, 100]  ,'k'); hold on
    if plot_sd=='y'
        plot([0:1:100],[mean_data_matrix+std_data_matrix] ,color_group,'linewidth',0.5); hold on
        plot([0:1:100],[mean_data_matrix-std_data_matrix]  ,color_group,'linewidth',0.5); hold on
    end
    xlabel('% stance phase');
    ylabel(' % bodyweight');
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

    %=================================
    %==                     (Cut)                            ==
    %==        initial time & End time               ==
    %==                                                         ==
    %=================================
    %==      Threshold    (mean 3 sd)             ==
    %=================================
    %         noise_sd=3;
    noise_extend=0;
    %         noise_fz=mean(fz_cut(1:20),1)+noise_sd*std(fz_cut(1:20),0,1);
    %         subplot(2,1,1); plot([0,100],[noise_fz,noise_fz],'k');

    max_f=max( fz_cut);
    noise_fz=max_f*0.01;


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
    %   plot(fz_signal(1)-1,                          0,  'ko','linewidth',2   ); hold on;
    x1=fz_signal(1);
    x2=fz_signal(  length(fz_signal)  );


    if plot_stard_end=='y'
        %     plot( x1-1,  0, [num2str(color_group(1)),'>'],'linewidth',1   ); hold on;
        %     plot( x2-1,  0, [num2str(color_group(1)),'<'],'linewidth',1   ); hold on;
        plot( [x1-1, x1-1], [ 0,  max_value/2], color_group,'linewidth',plot_linewidth   ); hold on;
        plot( [x2-1, x2-1],[ 0,  max_value/2], color_group,'linewidth',plot_linewidth   ); hold on;

        plot( x1-1, max_value/2, [num2str(color_group(1)),color_mark],'linewidth',1   ); hold on;
        plot( x2-1, max_value/2, [num2str(color_group(1)),color_mark],'linewidth',1   ); hold on;
    end

    %==========================
    %==========================
    group_semp(q,:)=[x1,x2, max_index, max_value];
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


