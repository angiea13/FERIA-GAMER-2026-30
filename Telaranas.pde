class Telarana{
  float x;
  float y;
  float u;
  float v;
  Telarana siguiente;
  Telarana(float basex, float basey){
    x=basex;
    y=basey;
    siguiente=null;
    u=0;
    v=0;
  }
void render(){
  fill(255);
  ellipse(x,y,20,50);
  if(siguiente!=null){
   line(x,y,siguiente.x,siguiente.y);  
   
  }

}
void Teletransportacion(Teletransportable personaje){
  if(dist(x,y,personaje.getX(),personaje.getY())<50 
  && personaje.teletransportacion(Telarana)){
    if(!dato){
    u=(siguiente.x-personaje.getX())/5;
    v=(siguiente.y-personaje.getY())/5;  
      dato=true;
    }
    personaje.setX(siguiente.x,u);
    personaje.setY(siguiente.y,v);
    personaje.teletransportandose( dato);
    personaje.teletransportacion(dato);
    Telarana=false;
  }
}

  
}
