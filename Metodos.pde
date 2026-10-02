void keyPressed() { // las teclas//
  if (key == 'a'||key== 'A') {
    p1.MoveLeft=true;
 
  }
  if (key == 'd'||key== 'D') {
    p1.MoveRight=true;

  }
  if (key == 'w'||key=='W') {
    p1.MoveUp=true;

  }
  if (key == 's'||key== 'S') {
    p1.MoveDown=true;
    
  }
  if(key=='p'||key=='P'){
    if(contador>=100){
   Telarana=true; 
   contador=0;
    }
  }
 
 }

   

void keyReleased() { 
  if (key == 'a'||key== 'A') {
    p1.MoveLeft=false;
  
  }
  if (key == 'd'||key== 'D') {
    p1.MoveRight=false;
    
  }
  if (key == 'w'||key== 'W') {
    p1.MoveUp=false;
 
  }
  if (key == 's'||key== 'S') {
    p1.MoveDown=false;
  
  }
    if(key=='p'||key=='P'){
    Telarana=false;
  }
 
}
