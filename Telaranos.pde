Telarana n1;
Telarana n2;
Telarana n3;
Jugador p1;
Telarana n4;
Telarana n5;
int contador=0;
boolean dato=false;
boolean Telarana;
void setup(){
  size(1200,800);
   n1=new Telarana(500,400);
 n2=new Telarana(800,200);
 n3= new Telarana(50,100);
 n4=new Telarana(1000,700);
 n5=new Telarana(1000,500);
 p1=new Jugador(600,400,30,30);
n1.siguiente=n2;
n2.siguiente=n3;
n3.siguiente=n1;
n5.siguiente=n4;
}
void draw(){
  background(255);if(Telarana){
    
    
  n1.Teletransportacion(p1);
    n3.Teletransportacion(p1);
  n5.Teletransportacion(p1);
  n2.Teletransportacion(p1);}
  p1.TodoP();
  n1.render();
  n2.render();
  n3.render();
  n4.render();
  n5.render();
  contador++;
}
