function [aaaa,abcd_in]=func_abcd_in(matrix_one,matrix_list, a,b,c,d);

x_ab=[a(1),b(1)];
y_ab=[a(2),b(2)];
x_bc=[b(1),c(1)];
y_bc=[b(2),c(2)];
x_cd=[c(1),d(1)];
y_cd=[c(2),d(2)];
x_da=[d(1),a(1)];
y_da=[d(2),a(2)];

ploy_ab=polyfit(x_ab,y_ab,1);
ploy_bc=polyfit(x_bc,y_bc,1);
ploy_cd=polyfit(x_cd,y_cd,1);
ploy_da=polyfit(x_da,y_da,1);

n=1; aaaa=[];
for i=1:length(matrix_list(:,1))
    yy_ab(i)=ploy_ab(1)*matrix_list(i,1) + ploy_ab(2);
    %yy_bc(i)=ploy_bc(1)*matrix_list(i,1) + ploy_bc(2);
    yy_cd(i)=ploy_cd(1)*matrix_list(i,1) + ploy_cd(2);
    %yy_da(i)=ploy_da(1)*matrix_list(i,1) + ploy_da(2);

    %xx_ab(i)=(matrix_list(i,2)-ploy_ab(2))/ploy_ab(1);
    xx_bc(i)=(matrix_list(i,2)-ploy_bc(2))/ploy_bc(1);
    %xx_cd(i)=(matrix_list(i,2)-ploy_cd(2))/ploy_cd(1);
    xx_da(i)=(matrix_list(i,2)-ploy_da(2))/ploy_da(1);
    if     yy_ab(i)>matrix_list(i,2) &...
            xx_bc(i)>matrix_list(i,1) &...
            yy_cd(i)<matrix_list(i,2) &...
            xx_da(i)<matrix_list(i,1)
        %=====  aaaa is plot(x,y)    ========
        aaaa(n,:)=[matrix_list(i,1), matrix_list(i,2)];
        n=n+1;
    end
end
% ===============================
%==   abcd_in is matrix coordinate  ===
% ===============================
for i=1:length(aaaa(:,1))
    abcd_in(i)=matrix_one(aaaa(i,2),aaaa(i,1));
end