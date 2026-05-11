clc
clear all
close all

dirVideo='Vlisto.mp4';
video = VideoReader(dirVideo);
numeroFrames = video.NumFrames;
Duracion=video.Duration;
FPS=numeroFrames/Duracion;
dt=1/FPS;

%Separar video en frames
for i=1:numeroFrames
    fv=read(video,i);
    %deteccion de ojeto 
    [filas,columnas, ~]=size(fv);
    HSV=rgb2hsv(fv);
    Sat=HSV(:,:,2); % Canal de Saturación
    Hue=HSV(:,:,1); % Canal de Hue (Matiz)
    SatCondicion=(Sat>0.8); % Máscara objeto 1 (Saturación muy alta)
    Objetos = SatCondicion .* Hue;
    x=[1:columnas];
    y=[1:filas];

    Obj1=(Objetos>0.8);
    Obj2=(Objetos>0.4 & Objetos<0.55);
    Obj3=(Objetos>0.55 & Objetos<0.65);

    %Obtener centroide obj1
    f1x=sum(Obj1,1);
    f1y=sum(Obj1,2)';

    if sum(f1x)>0
        f1xc=sum(x.*f1x)/sum(f1x);
        f1yc=sum(y.*f1y)/sum(f1y);
    else
        f1xc = NaN;
        f1yc = NaN;
    end

    %Obtener centroide obj2
    f2x=sum(Obj2,1);
    f2y=sum(Obj2,2)';

    if sum(f2x)>0
        f2xc=sum(x.*f2x)/sum(f2x);
        f2yc=sum(y.*f2y)/sum(f2y);
    else
        f2xc = NaN;
        f2yc = NaN;
    end

    %Obtener centroide obj3
    f3x=sum(Obj3,1);
    f3y=sum(Obj3,2)';

    if sum(f3x)>0
        f3xc=sum(x.*f3x)/sum(f3x);
        f3yc=sum(y.*f3y)/sum(f3y);
    else
        f3xc=NaN;
        f3yc=NaN;
    end

    %Obtener posicion por cada objeto en m
    
    D_real = 3.5; %cm
    
    area1 = sum(Obj1(:));
    if area1 > 0
        F1(i)=D_real/(2*sqrt(area1/pi));
        Cx1(i)=f1xc * F1(i);
        Cy1(i)=f1yc * F1(i);
    else
        F1(i)=NaN;
        Cx1(i)=NaN;
        Cy1(i)=NaN;
    end
    
    area2=sum(Obj2(:));
    if area2 > 0
        F2(i)=D_real/(2*sqrt(area2/pi)); 
        Cx2(i)=f2xc*F2(i);
        Cy2(i)=f2yc*F2(i);
    else
        F2(i)=NaN;
        Cx2(i)=NaN; 
        Cy2(i)=NaN;
    end
    
    area3=sum(Obj3(:));
    if area3>0
        F3(i)=D_real/(2*sqrt(area3/pi)); 
        Cx3(i)=f3xc*F3(i);
        Cy3(i)=f3yc*F3(i);
    else
        F3(i)=NaN;
        Cx3(i)=NaN;
        Cy3(i)=NaN;
    end

end


escV = 0.1; 
escA = 0.1; 

for l=2:length(Cx1)
    Vx1(l-1)=(Cx1(l)-Cx1(l-1))/dt;
    Vy1(l-1)=(Cy1(l)-Cy1(l-1))/dt;
    V1(l-1)=sqrt(Vx1(l-1)^2+Vy1(l-1)^2);
    Vx2(l-1)=(Cx2(l)-Cx2(l-1))/dt;
    Vy2(l-1)=(Cy2(l)-Cy2(l-1))/dt;
    V2(l-1)=sqrt(Vx2(l-1)^2+Vy2(l-1)^2);
    Vx3(l-1)=(Cx3(l)-Cx3(l-1))/dt;
    Vy3(l-1)=(Cy3(l)-Cy3(l-1))/dt;
    V3(l-1)=sqrt(Vx3(l-1)^2+Vy3(l-1)^2);
end
 
for l=2:length(Vx1)
    Ax1(l-1)=(Vx1(l)-Vx1(l-1))/dt;
    Ay1(l-1)=(Vy1(l)-Vy1(l-1))/dt;
    A1(l-1)=sqrt(Ax1(l-1)^2+Ay1(l-1)^2);
    Ax2(l-1)=(Vx2(l)-Vx2(l-1))/dt;
    Ay2(l-1)=(Vy2(l)-Vy2(l-1))/dt;
    A2(l-1)=sqrt(Ax2(l-1)^2+Ay2(l-1)^2);
    Ax3(l-1)=(Vx3(l)-Vx3(l-1))/dt;
    Ay3(l-1)=(Vy3(l)-Vy3(l-1))/dt;
    A3(l-1)=sqrt(Ax3(l-1)^2+Ay3(l-1)^2);
end  
% Reducir el tamaño de imagen sin es necesario. 
dimensionesFijas = [100, 100, 640, 480];

% Producir tres videos:
% El primero mostrará el overlay de toda la trayectoria recorrida por cada uno de los objetos en un plano XY.
v1 = VideoWriter('Trayectoria.mp4', 'MPEG-4');
v1.FrameRate = FPS;
open(v1);
h1 = figure('Name', 'Generando Trayectoria'); 
h1.Position = dimensionesFijas;
for i = 1:numeroFrames
imshow(read(video, i)); 
hold on;
plot(Cx1(1:i)./F1(1:i),Cy1(1:i)./F1(1:i),'r','LineWidth',2); 
plot(Cx2(1:i)./F2(1:i),Cy2(1:i)./F2(1:i),'g','LineWidth',2); 
plot(Cx3(1:i)./F3(1:i),Cy3(1:i)./F3(1:i),'b','LineWidth',2);
title(['Trayectoria - Frame: ', num2str(i)]);

frameActual = getframe(h1);
writeVideo(v1, frameActual);
hold off;
end
close(v1);

% El segundo mostrará el overlay de los vectores de velocidad XY, desde el centro de cada objeto. Su magnitud será una representación de la rapidez de cambio de posición y su dirección representará la dirección de movimiento. 
v2 = VideoWriter('Velocidad.mp4', 'MPEG-4');
v2.FrameRate = FPS;
open(v2);
h2 = figure('Name', 'Generando Velocidad');
h2.Position = dimensionesFijas; 
for i = 1:length(Vx1)
    imshow(read(video, i)); hold on;
    quiver(Cx1(i)/F1(i),Cy1(i)/F1(i),(Vx1(i)*escV)/F1(i),(Vy1(i)*escV)/F1(i),0,'r','LineWidth',2);
    quiver(Cx2(i)/F2(i),Cy2(i)/F2(i),(Vx2(i)*escV)/F2(i),(Vy2(i)*escV)/F2(i),0,'g','LineWidth',2);
    quiver(Cx3(i)/F3(i),Cy3(i)/F3(i),(Vx3(i)*escV)/F3(i),(Vy3(i)*escV)/F3(i),0,'b','LineWidth',2);
    title(['Vectores Velocidad - Frame: ', num2str(i)]);
    writeVideo(v2, getframe(h2));
    hold off;
end
close(v2);

% El tercero mostrará el overlay de los vectores de aceleración XY, desde el centro de cada objeto. Su magnitud será una representación de la rapidez de cambio de velocidad y su dirección representará la dirección de movimiento. 
v3 = VideoWriter('Aceleracion.mp4', 'MPEG-4');
v3.FrameRate = FPS;
open(v3);
h3 = figure('Name', 'Generando Aceleración');
h3.Position = dimensionesFijas; 
for i = 1:length(Ax1)
    imshow(read(video, i)); hold on;
    quiver(Cx1(i)/F1(i),Cy1(i)/F1(i),(Ax1(i)*escA)/F1(i),(Ay1(i)*escA)/F1(i),0,'r','LineWidth',2);
    quiver(Cx2(i)/F2(i),Cy2(i)/F2(i),(Ax2(i)*escA)/F2(i),(Ay2(i)*escA)/F2(i),0,'g','LineWidth',2);
    quiver(Cx3(i)/F3(i),Cy3(i)/F3(i),(Ax3(i)*escA)/F3(i),(Ay3(i)*escA)/F3(i),0,'b','LineWidth',2);
    title(['Vectores Aceleración - Frame: ', num2str(i)]); 
    writeVideo(v3, getframe(h3));
    hold off;
end
close(v3);

% Todos los overlay deben ser congruentes con el color del objeto descrito. 
% Generar todas las graficas de posición, velocidad y aceleración de cada variable contra el tiempo y entre variables (modo XY).

t=(0:numeroFrames-1)*dt; % Tiempo para posición
tv=(0:numeroFrames-2)*dt; % Tiempo para velocidad 
ta=(0:numeroFrames-3)*dt; % Tiempo para aceleración

%Variables vs Tiempo
figure('Name', 'Variables vs tiempo');

% Objeto 1 
subplot(3,3,1); 
plot(t,Cx1,t,Cy1); 
title('Posición Obj 1'); 
grid on; 
legend('Px1','Py1');
ylabel('Posición (cm)');
subplot(3,3,4); 
plot(tv,V1); 
title('Velocidad Obj 1'); 
grid on; 
ylabel('Velocidad (cm/s)');
subplot(3,3,7); 
plot(ta,A1); 
title('Aceleración Obj 1'); 
grid on; 
xlabel('Tiempo (s)');
ylabel('Aceleración (cm/s^2)');

%Objeto 2
subplot(3,3,2); 
plot(t,Cx2,t,Cy2); 
title('Posición Obj 2'); 
grid on; 
legend('Px2','Py2');
subplot(3,3,5); 
plot(tv,V2); 
title('Velocidad Obj 2'); 
grid on;
subplot(3,3,8); 
plot(ta, A2); 
title('Aceleración Obj 2'); 
grid on; 
xlabel('Tiempo (s)');

%Objeto 3
subplot(3,3,3); 
plot(t,Cx3,t,Cy3); 
title('Posición Obj 3'); 
grid on; 
legend('Px3','Py3');
subplot(3,3,6); 
plot(tv, V3); 
title('Velocidad Obj 3'); 
grid on;
subplot(3,3,9);
plot(ta, A3); 
title('Aceleración Obj 3'); 
grid on; 
xlabel('Tiempo (s)');


%Graficas formato XY
figure('Name', 'Gráficas XY');

%Trayectorias X vs Y
subplot(3,3,1); 
plot(Cx1,Cy1); 
title('Trayectoria Obj 1'); 
xlabel('Cx1 (cm)'); 
ylabel('Cy1 (cm)'); 
grid on;
subplot(3,3,2); 
plot(Cx2,Cy2); 
title('Trayectoria Obj 2'); 
xlabel('Cx2 (cm)'); 
ylabel('Cy2 (cm)'); 
grid on;
subplot(3,3,3); 
plot(Cx3,Cy3); 
title('Trayectoria Obj 3'); 
xlabel('Cx3 (cm)'); 
ylabel('Cy3 (cm)'); 
grid on;

% Velocidad Vx vs Vy
subplot(3,3,4); 
plot(Vx1,Vy1); 
title('Velocidad XY Obj 1'); 
xlabel('Vx1 (cm/s)'); 
ylabel('Vy1 (cm/s)'); 
grid on;
subplot(3,3,5); 
plot(Vx2,Vy2); 
title('Velocidad XY Obj 2'); 
xlabel('Vx2 (cm/s)'); 
ylabel('Vy2 (cm/s)'); 
grid on;
subplot(3,3,6); 
plot(Vx3,Vy3); 
title('Velocidad XY Obj 3'); 
xlabel('Vx3 (cm/s)'); 
ylabel('Vy3 (cm/s)'); 
grid on;

%Aceleración Ax vs Ay 
subplot(3,3,7); 
plot(Ax1,Ay1); 
title('Aceleración XY Obj 1'); 
xlabel('Ax1 (cm/s^2)'); 
ylabel('Ay1 (cm/s^2)'); 
grid on;
subplot(3,3,8); 
plot(Ax2,Ay2); 
title('Aceleración XY Obj 2'); 
xlabel('Ax2 (cm/s^2)'); 
ylabel('Ay2 (cm/s^2)'); 
grid on;
subplot(3,3,9); 
plot(Ax3,Ay3); 
title('Aceleración XY Obj 3'); 
xlabel('Ax3 (cm/s^2)'); 
ylabel('Ay3 (cm/s^2)'); 
grid on;