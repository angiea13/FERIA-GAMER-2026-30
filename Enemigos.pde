class Enemy {
  float x,y,w,h;
  float vx;
  float vy;
  float mag;
  float speed;
  float radio_Telarana;
  Enemy(float x,float y){
    this.x=x;
    this.y=y;
    w=20;
    h=20;
    speed=4;
    vx=random(-1,1);
    vy=random(-1,1);
    mag=vx*vx+vy*vy;
    if(mag!=0){
      vx= (vx*speed)/mag;
      vy= (vy*speed)/mag;
    }
    speed=4;
   radio_Telarana=200;
  }
  void render(){
    fill(0,255,0);
    ellipse(x,y,w,h);
  }
  void move(){
   vx=random(-1,1);
    vy=random(-1,1);
    mag=vx*vx+vy*vy;
    if(mag!=0){
      vx= (vx*speed)/mag;
      vy= (vy*speed)/mag;
    }
    if(x>1200 || x<0){
      vx*=-1;
    }
    if(y>1200 || y<0){
      vy*=-1;
    }
  }
  void revisar_Nodos(){
    
  }
  
}
