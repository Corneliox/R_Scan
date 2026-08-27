clc; close all; clear all;
open_file='G:\coba rs scan\';
% open_file='C:\c\';
open_level='G:\c\';
% save_file='C:\b\rscop_box_pressure\txt_step\';
% open_file='C:\c\';
save_file='G:\c\';
sampling_rate=1/500;
level_1=90;  level_2=70;  level_3=69;level_4=68;

% %===========================
% %===========================
% no_man1=[0:9];
% no_man2=[10:17,19:46,50:78];
% no_man3=[0:9];
% no_man4=[10:17,19:46,50:78];
% %===========================
% t00_1='_t00'; t00_2='_t0';
% LR='L';
% for i=1:length(no_man1)
%     no_group1(i,:)=[  LR ,t00_1, num2str(no_man1(i))   ] ;
% end
% for i=1:length(no_man2)
%     no_group2(i,:)=[   LR, t00_2, num2str(no_man2(i))   ] ;
% end
% % ++++++++++++++++++++++++++++++++++
% LR='R';
% for i=1:length(no_man3)
%     no_group3(i,:)=[   LR, t00_1, num2str(no_man3(i))   ] ;
% end
% for i=1:length(no_man4)
%     no_group4(i,:)=[   LR , t00_2, num2str(no_man4(i))   ] ;
% end
% %===========================
% no_man=[
%     no_group1;
%     no_group2;
%     no_group3;
%     no_group4
%     ];
no_man=[
'R_t063'
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

% for w=366:length(no_man_step(:,1))
for w=1
    close all
    clear i   j   k   map_raw   length_Fn_cm...
        length_Fp_ch  length_Fn_a  length_Fn_b  cop_roll
    cop_divide=10;
    %===========================
 map_level_max=load([  open_level, 'map_level_max_'       ,num2str(no_man_step(w,:)),'.txt']);
%     map_raw     =load([  [num2str(open_file)], 'map_raw_',        [num2str(no_man_step(w,:))],'.txt']);
  anatomy_p=load([  [num2str(open_file)], 'anatomy_p_'             ,[num2str(no_man_step(w,:))],'.txt']);
    xy_cop_i100= load([  [num2str(open_file)], 'xy_cop_i100_3_' ,[num2str(no_man_step(w,:))],'.txt']);
    %+++++++++++++++++++++++++++++++
    %++                                                       ++
    %++           Pressure Map                      ++
    %++                                                       ++
    %+++++++++++++++++++++++++++++++
    %==  plot =presure value is square and multiply 10  ===
    %==  that will enhance the readability   ===
    %     subplot(1,2,1);
%     map=sqrt(map_raw).*10;
%     surf(map_raw);hold on;
   surf( map_level_max);hold on;colorbar
    x_copi=xy_cop_i100(:,1);
    y_copi=xy_cop_i100(:,2);
    cop_zi=x_copi(:,1).*0+level_1;
    plot3(x_copi, y_copi,cop_zi,'w','linewidth',3 );hold on;grid on
    plot3(x_copi, y_copi,cop_zi,'r.-','linewidth',1 );hold on;grid on
    %     %++++++++++++++++++++++++++++++
    %     %+++   Medial and Lateral line           ++
    %     %===   heel point & toe-point       ====
    %     %++++++++++++++++++++++++++++++
    xy_lat_for=    [anatomy_p(2,2);anatomy_p(2,4)];
    xy_lat_real=   [anatomy_p(2,1);anatomy_p(2,3)];
    xy_med_for= [anatomy_p(1,2);anatomy_p(1,4)];
    xy_med_real=[anatomy_p(1,1);anatomy_p(1,3)];
    xy_toe=         [anatomy_p(3,2);anatomy_p(3,4)];
    xy_mt=          [anatomy_p(4,1);anatomy_p(4,2)];
    xy_heel=        [anatomy_p(3,1);anatomy_p(3,3)];
    xy_ai=            [anatomy_p(4,3);anatomy_p(4,4)];

    x_a=[xy_med_real(1),xy_med_for(1)];
    y_a=[xy_med_real(2),xy_med_for(2)];;
    x_b=[xy_lat_real(1),   xy_lat_for(1)];;
    y_b=[xy_lat_real(2),   xy_lat_for(2)];;

    x_ct_p=xy_toe(1);
    y_ct_p=xy_toe(2);
    x_cd1_p=xy_mt(1);
    y_cd1_p=xy_mt(2);
    x_ch_p=xy_heel(1);
    y_ch_p=xy_heel(2);
    %+++++++++++++++++++++++++++++
    %+++          Foox axis                     +++
    %+++++++++++++++++++++++++++++
    %==  x_cm= (x axis)(center line)(middle line segmen) ==
    x_cm=[ (x_a(1)+x_b(1))/2,...
        (x_a(2)+x_b(2))/2,   ];
    y_cm=[ (y_a(1)+y_b(1))/2,...
        (y_a(2)+y_b(2))/2   ];
    ploy_a=polyfit(x_a,y_a,1);
    ploy_b=polyfit(x_b,y_b,1);
    ploy_cm=polyfit(x_cm,y_cm,1);
    %++++++++++++++++++++++++++++++
    %++                                               ++++
    %++     % foot 1/3 ( except toe)     ++++
    %++                                               ++++
    %++++++++++++++++++++++++++++++
    %===    c axis except toe
    %===    x_chp, y_chp: heel;
    %===               cm1_p: 1/3 point;
    %===               cm2_p: 2/3 point;
    %===               cm3_p: 2/3 point;
    %===  (a-b)/(x-b)=3/1 ; x=(a-b)/3 +b

    x_cd2_p=[(x_ch_p- x_cd1_p)/3 + x_cd1_p];
    y_cd2_p=[(y_ch_p- y_cd1_p)/3 + y_cd1_p];
    % text(x_cd2_p,y_cd2_p,'\leftarrow cd2_p');

    x_cd3_p=[(x_ch_p- x_cd1_p)/3*2 + x_cd1_p];
    y_cd3_p=[(y_ch_p- y_cd1_p)/3*2 + y_cd1_p];
    % text(x_cd3_p,y_cd3_p,'\leftarrow cd3_p');

    x_ch_cd=[x_cd1_p, x_cd2_p, x_cd3_p,x_cm(1), x_cm(2)];
    y_ch_cd=[y_cd1_p, y_cd2_p, y_cd3_p,y_cm(1), y_cm(2)];
    for i=1:length(x_ch_cd)
        length_ch_cd(i)=sqrt( (x_ch_cd(i) - x_ch_p )^2+...
            (y_ch_cd(i) - y_ch_p )^2  );
    end
    %+++++++++++++++++++++++++++++++++++
    %+++                                            ++++++++++
    %+++   Foox axis perpendicular   ++++++++++
    %+++      heel point & toe-point    ++++++++++
    %+++                                            ++++++++++
    %+++++++++++++++++++++++++++++++++++
    x_c=[x_ch_p,x_ct_p, x_cd3_p,x_cd2_p,x_cd1_p,x_cm(1), x_cm(2)];
    y_c=[y_ch_p,y_ct_p, y_cd3_p,y_cd2_p,y_cd1_p,y_cm(1), y_cm(2)];
    %=============================
    %==  draw 2 times in foot and intersect
    %==      (COP Fn & cm(footaxis)) ====
    %=============================
    for i=1: length(x_c);
        %== (1) x2= (a) x1 + (b), perpendicular  (a) x2 = (-1) x1 +c
        %==  x2= (-1) x1/ (a)   +  constant_vc
        %==   U.V=x1x2 + y1y2  = a + (-1)a
        %==   x2= (a) x1 + constant_vc

        %===== for i end  key is under here   ====
        constant_vc=ploy_cm(1)*y_c(i)   + x_c(i);
        ploy_vc=[-1/ploy_cm(1),  constant_vc/ploy_cm(1)];
        %==  vc & a  intersect    ==
        function_vc_a  = [-ploy_a(1),1 ;...
            -ploy_vc(1),1];
        constant_vc_a = [ ploy_a(2); ...
            ploy_vc(2)];
        vc_a=inv( function_vc_a )* constant_vc_a ;
        %==  vc & b  intersect    ==
        function_vc_b  = [-ploy_b(1),1 ;...
            -ploy_vc(1),1];
        constant_vc_b = [ ploy_b(2); ...
            ploy_vc(2)];
        vc_b=inv( function_vc_b )* constant_vc_b ;
        x_vc_a(i)=vc_a(1);
        x_vc_b(i)=vc_b(1);
        y_vc_a(i)=vc_a(2);
        y_vc_b(i)=vc_b(2);
    end
    %=================================
    %==                                                         ==
    %==        BOX    MT devide                       ==
    %==                                                         ==
    %=================================
    x_aa= [ x_vc_a(4),x_vc_b(4)];
    y_aa=  [ y_vc_a(4),y_vc_b(4)];
    x_bb= [ x_vc_a(5),x_vc_b(5)];
    y_bb=  [ y_vc_a(5),y_vc_b(5)];
    %     plot(x_aa,y_aa, 'rv' , 'linewidth',5)
    %     plot(x_bb,y_bb, 'mv' , 'linewidth',10)
    %     plot(x_aa(1),y_aa(1), 'kv' , 'linewidth',5)
    %===  (a-b)/(x-b)=3/1 ; x=(a-b)/3 +b
    %////////////////////////////////////////////////////////
    %////////////////////////////////////////////////////////
    %     ratio_c=[35,15,15];
    %     ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2),ratio_c(1)+ratio_c(2)+ratio_c(3)];
    ratio_c=[30,20,20];
    ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2),ratio_c(1)+ratio_c(2)+ratio_c(3)];
    %     ratio_c=[30,25];
    %     ratio_cc=[ratio_c(1),ratio_c(1)+ratio_c(2)];
    %////////////////////////////////////////////////////////
    %////////////////////////////////////////////////////////
    for i=1:length(ratio_cc)
        x_cc(i)=(x_aa(2)- x_aa(1))/100*ratio_cc(i) +x_aa(1);
        y_cc(i)=(y_aa(2)- y_aa(1))/100*ratio_cc(i) +y_aa(1);
    end
    % #############################
    % #############################
    [x_dd,y_dd]=func_perpendical_point_to_line(x_aa,y_aa, x_bb,y_bb,x_cc, y_cc);
    % #############################
    % #############################
    x_cd2_d=x_cc;
    y_cd2_d=y_cc;
    x_cd3_d=x_dd;
    y_cd3_d=y_dd;

    %================================
    %==                                                         ==
    %==        BOX    Toe devide                     ==
    %==                                                         ==
    %================================
    x_bb= [ x_vc_a(2),x_vc_b(2)];
    y_bb=  [ y_vc_a(2),y_vc_b(2)];
    % plot(x_aa,y_aa, 'rv' , 'linewidth',5)
    % plot(x_bb,y_bb, 'mv' , 'linewidth',10)
    % plot(x_aa(1),y_aa(1), 'kv' , 'linewidth',5)
    %===  (a-b)/(x-b)=3/1 ; x=(a-b)/3 +b
    % #############################
    % #############################
    [x_dd,y_dd]=func_perpendical_point_to_line(x_aa,y_aa, x_bb,y_bb,x_cc, y_cc);
    % #############################
    % #############################
    x_ct_d=x_dd;
    y_ct_d=y_dd;
    %=============================
    %==  draw 2 times in foot and intersect
    %==      (medial and lateral line)====
    %==        (foot axis)              ====
    %=============================
    z_vc=x_vc_a(1,:).*0+level_3;
    plot3(x_a,y_a,[level_1,level_1],'yo-','linewidth',1);hold on;
    plot3(x_b,y_b,[level_1,level_1],'yo-','linewidth',1);hold on;
    plot3([x_a(1),x_b(1)],[y_a(1),y_b(1)],[level_1,level_1],'y-o' ,'linewidth',1);
    plot3([x_a(2),x_b(2)],[y_a(2),y_b(2)],[level_1,level_1],'y-o' ,'linewidth',1);
    plot3(x_cm(1),y_cm(1),[level_2,level_2],'k^','linewidth',2 );
    plot3(x_cm(2),y_cm(2),[level_2,level_2],'ksquare','linewidth',2 );
    plot3([x_vc_a],[y_vc_a],z_vc,'k-^','linewidth',1);hold on;
    plot3([x_vc_b],[y_vc_b],z_vc,'k-^','linewidth',1);hold on;
    plot3([x_ch_p,x_ct_p],[y_ch_p,y_ct_p],[level_4,level_4],'k-o','linewidth',2);hold on;
    for i=1:length(x_vc_a)-1
        plot3([x_vc_a(i),x_vc_b(i)],[y_vc_a(i),y_vc_b(i)],[z_vc(i),z_vc(i)],'c-^','linewidth',2);hold on;
    end

    plot3( [((x_vc_a(1)+x_vc_b(1))/2), ((x_vc_a(2)+x_vc_b(2))/2) ],...
        [((y_vc_a(1)+y_vc_b(1))/2), ((y_vc_a(2)+y_vc_b(2))/2)],...
        [level_4,level_4],...
        'k-o','linewidth',2);

    for i=length(x_vc_a)-1:length(x_vc_a)
        plot3([x_vc_a(i),x_vc_b(i)],[y_vc_a(i),y_vc_b(i)],[z_vc(i),z_vc(i)],'k-^','linewidth',2);hold on;
    end

    for i=1: length(x_cc);
        plot3( [x_cd2_d(i),x_ct_d(i)] , [y_cd2_d(i),y_ct_d(i)],[z_vc(i),z_vc(i)], 'y-', 'linewidth',3)
    end
    %=================================
    %==                                                         ==
    %==            Box define                            ==
    %==        heel point & toe-point               ==
    %==                                                         ==
    %=================================
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
    %    plot([x(i),x(i)] ,[y1(i),y2(i)],'color',box_color(i,:),'linewidth',10);hold on;

    x_text=-10;
    y_text=30;
    y_space=-2;
    text_list=[
        ' 1:Toe 1   ';
        ' 2:Toe 2   ';
        ' 3:Toe 3   ';
        ' 4:Toe 4-5 ';
        ' 5:MT 1    ';
        ' 6:MT 2    ';
        ' 7:MT 3    ';
        ' 8:MT 4-5  ';
        ' 9:Mid med ';
        '10:Mid lat ';
        '11:Heel med';
        '12:Heel lat'];


    x_a=x_vc_a   ; y_a=y_vc_a;
    x_b=x_vc_b   ; y_b=y_vc_b;
    x_c=x_c        ; y_c=y_c;
    x_t=x_ct_d    ; y_t=y_ct_d;
    x_3=x_cd3_d ; y_3=y_cd3_d;
    x_2=x_cd2_d ; y_2=y_cd2_d;

    box(1,:)=  [x_t(1),y_t(1)  ,  x_a(2),y_a(2) ,  x_a(5),y_a(5)  , x_3(1),y_3(1)  ];
    box(2,:)=  [x_t(2),y_t(2)  ,  x_t(1),y_t(1)  ,  x_3(1),y_3(1)  , x_3(2),y_3(2)  ];
    box(3,:)=  [x_t(3),y_t(3) , x_t(2),y_t(2)   ,  x_3(2),y_3(2)  , x_3(3),y_3(3) ];
    box(4,:)=  [x_b(5),y_b(5) , x_t(3),y_t(3)   ,  x_3(3),y_3(3)  , x_b(7),y_b(7) ];
    box(5,:)=  [x_3(1),y_3(1) , x_a(5),y_a(5)  ,  x_a(4),y_a(4)  , x_2(1),y_2(1)  ];
    box(6,:)=  [x_3(2),y_3(2) , x_3(1),y_3(1)  ,  x_2(1),y_2(1)  , x_2(2),y_2(2)  ];
    box(7,:)=  [x_3(3),y_3(3) , x_3(2),y_3(2)  ,  x_2(2),y_2(2)  , x_2(3),y_2(3) ];
    box(8,:)=  [x_b(7),y_b(7) , x_3(3),y_3(3)  ,  x_2(3),y_2(3)  , x_b(4),y_b(4) ];
    box(9,:)=  [x_c(4),y_c(4) , x_a(4),y_a(4)  ,  x_a(3),y_a(3)  ,  x_c(3),y_c(3) ];
    box(10,:)=  [x_b(4),y_b(4) , x_c(4),y_c(4)  ,  x_c(3),y_c(3)  , x_b(3),y_b(3) ];
    box(11,:)=  [x_c(3),y_c(3) , x_a(3),y_a(3)  ,  x_a(1),y_a(1)  , x_c(1),y_c(1)  ];
    box(12,:)=[x_b(3),y_b(3) , x_c(3),y_c(3)  ,  x_c(1),y_c(1)  , x_b(1),y_b(1) ];

    %     plot3([x_a(2)],[y_a(2)],[level_1,level_1],'r^','linewidth',3);hold on;

    box_level_1=[box(1,1:2:8), box(1,1)]*0+level_1;
    for i=1:length(box(:,1))
        text(x_text, y_text+i*y_space, text_list(i,:),'BackgroundColor',box_color(i,:));
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'c-','linewidth',2);hold on;
        plot3([box(i,1:2:8), box(i,1)],  [box(i,2:2:8), box(i,2)], box_level_1,   'k-','linewidth',1);hold on;
    end

    view(0,90);grid on;   axis equal;hold on;

    %================================
    %================================
    %==            Box check A B C D              ==
    %==         (repeat need pick point)          ==
    %==                 clockwise                        ==
    %==    left up    :A        right up    :B       ==
    %==    left down:D       right down:C       ==
    %================================
    abcd_list=['a','b','c','d'];
    for i=1:length(box(:,1))
        text( (box(i,1)+box(i,3))/2, (box(i,4)+box(i,6))/2, level_1,text_list(i,1:2),'BackgroundColor',box_color(i,:), 'fontsize',8);
%                         for j=1:4
%                             text(box(i,j*2-1),box(i,j*2), level_1, abcd_list(j),'BackgroundColor',...
%                                 box_color(i,:), 'fontsize',12);
%                         end
%                         [x_i, y_i]=ginput(1);
    end
    %=================================
    %=================================
    %axis([-5 30, 0 40, 0 80 ]);set(gca, 'xtick', [-5: 5: 30], 'ytick', [0: 5: 45], 'ztick', [0: 5: 80]);

    save([save_file,'xy_box12_', num2str(no_man_step(w,:)),'.txt'],'box' ,'-ascii')

         title([num2str(no_man_step(w,:)), '  [',num2str(w), ']  ' , num2str(ratio_c)] );
    currFig1 = get(0,'CurrentFigure');
    saveas (currFig1,[save_file, 'xy_box12_', num2str(no_man_step(w,:)) ],'jpg' )
end
