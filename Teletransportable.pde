interface Teletransportable {
  float getX();
  void setX(float x, float u);
  void setY(float y,float v);
  float getY();
  boolean teletransportacion(boolean dato);
  boolean teletransportandose(boolean dato);
}

class Jugador implements Teletransportable {
  float x,y,w,h;
  Estado_Jugador estado;
  float factor;
  boolean MoveRight;
  boolean MoveLeft;
  boolean MoveUp;
  boolean MoveDown;
  int speed;
  
  Jugador(float x,float y, float w,float h) {
    
    this.x=x;
    
    this.y=y;
    this.w=w;
    this.h=h;
    MoveRight=MoveLeft=MoveUp=MoveDown=false;
    speed=5;
    estado=Estado_Jugador.Moviendose;
    factor=1;
    
  }
  
  void render() {
    
    if(estado.equals(Estado_Jugador.Moviendose)){
      fill(255,0,0);
      ellipse(x,y,w,h);
    } else{
      fill(255);
      ellipse(x,y,w/2,h/2);
    }
  }
  
  void ControlEstados() {
    if(teletransportandose(dato))estado=Estado_Jugador.En_Telarana;
    else{estado=Estado_Jugador.Moviendose;
    }
  }
  
  void MoveX() {
    if(MoveRight)x+=speed*factor;
    if(MoveLeft)x-=speed*factor;
  }
  
  void MoveY() {
    if(MoveUp)y-=speed*factor;
    if(MoveDown)y+=speed*factor;
  }
  
  void Normalizador() {
    if( (MoveRight||MoveLeft)&&(MoveUp||MoveDown)){
      factor=1/sqrt(2);
    } else {
      factor=1;
    }
  }
  
  public float getX(){
    return x;
  }
  
  public float getY() {
    return y;
  }
  
  public void setX(float limiteX, float u) {
    if(x!=limiteX){   
        x=limiteX;
    }    
    dato=false;    
  }
  
  public void setY(float limiteY,float v) {
    if(y!=limiteY){
        y=limiteY;
    }
        dato=false;
    }
  
  public boolean teletransportacion(boolean dato) {
    return dato;
  }
  
  public boolean teletransportandose(boolean dato) {
    return dato;
  }
  
 void TodoP() {
   ControlEstados();
   if(estado.equals(Estado_Jugador.Moviendose)) {
     MoveX();
     MoveY();}
     render();
   }
}

enum Estado_Jugador{
  Moviendose,
  En_Telarana,
  EnDash;
}
