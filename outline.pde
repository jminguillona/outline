import java.io.File;

//
// outline: takes an image (image.jpg) and creates a sketch version
//
// procsilas (procsilas@hotmail.com / http://procsilas.net)
//

//
// pendent:
//
// * combinar brightness/saturation/hue
// * calcular THR a partir de l'histograma 
//

void setup() {
  // per si de cas
  img = loadImage("mao.jpg");
  //selectInput("Image:","llegeixImatge");

  if (0==1) {
  int [] hist = new int[100];
  for (int h=0; h<100; h++)
    hist[h]=0; 
  int n=(img.width-2*B)*(img.height-2*B);
  for (int i=B; i<(img.width-B); i++) {
    for (int j=B; j<(img.height-B); j++) {
      float x=fVar(i,j);
      hist[int(x)]++;       
    }
  }
  for (int h=0; h<100; h++) {
    n-=hist[h];
    println(h+": "+hist[h]+" ("+n+")");
  }
  }

  punts = new float[NP][2];
  cpunts = new color[NP];
  usat = new int[NP];

  size(img.width, img.height);
  background(#FFFFFF);
  ellipseMode(CENTER);
}

// parameters
// NO real control, so be careful

int NP=8000; // 1000 for line art, 10000 for complex images, O(N^2) so be patient!!!
int B=1; // try 1, 2 or 3
float MAXTHR=36; // range 5-150
float THR=MAXTHR;
float MINTHR=6;
float MAXMD=12.0; // range 0-20
float MD=MAXMD; 
float MINMD=2.0;
// minimum distance for drawing points is MINMD+ALFAMD*(MAXMD-MINMD)
float ALFAMD=0; 

int NTRIALS=5; // range 1-10

int NMP=1; // range 1-15 (draw a line to the NMP-th closest point)

float SW=4.0; // strokeWeight, inversely proportional to line length

float[][] punts;
color[] cpunts;
int [] usat;
int [] NmP=new int[NMP];
float [] NdmP=new float[NMP];

int inici=0;

PImage img;
String iName;

void llegeixImatge(File fs) {
  if (fs!=null) {
    iName=fs.getAbsolutePath();
    println(iName);
    img = loadImage(iName);
    img.loadPixels();
  }
}

// get pixel brightness
float gpb(int x, int y) {
  color c=img.pixels[y*img.width+x];
  return brightness(c);
}

float fVar(int x, int y) {
  // neighborhood 2B+1x2B+1 pixels
  float m=0;
  for (int k1=-B; k1<=B; k1++) {
    for (int k2=-B; k2<=B; k2++) {
      color c=img.pixels[(y+k1)*img.width+(x+k2)];
      m+=brightness(c);
    }
  }
  m/=float((2*B+1)*(2*B+1));
  float v=0;
  for (int k1=-B; k1<B; k1++) {
    for (int k2=-B; k2<B; k2++) {
      color c=img.pixels[(y+k1)*img.width+(x+k2)];
      v+=(brightness(c)-m)*(brightness(c)-m);
    }
  }
  v=sqrt(v)/(float) (2*B+1);    

  return v;
}

int creaPunt(int i) {
  int nint1=0;
  int nint2=0;
  
  int puntOK=0;
  
  while ((i<NP) && (puntOK!=1)) {
  
    int x=B+int(random(width-2*B));
    int y=B+int(random(height-2*B));

    println(i+" ("+NP+") = "+x+", "+y+": "+THR+", "+MD);

    // points need to be at least MD far from each other
    int flag=0;
    if (MD>0.0) {  
      for (int j=0; flag==0 && j<i; j++) {
        if (dist(x, y, punts[j][0], punts[j][1])<MD) {
          flag=1;
        }
      }
    }

    if (flag==0) { 
      nint1=0;
      float f=fVar(x, y);

      // use only "valid" points      
      if (f>=THR) {
        nint2=0;
        punts[i][0]=x;
        punts[i][1]=y;
        cpunts[i]=img.pixels[y*img.width+x];
        usat[i]=0;
        i++;
        
        puntOK=1;
        
        fill(#000000);
        ellipse(x,y,MD,MD);
      } 
      else {
        nint2++;
        if (nint2>=NTRIALS) {
          // relax conditions
          THR/=(1+1.0/float(NP));
          if (THR<MINTHR) {
            THR=MINTHR;
          }
          MD/=(1+1.0/float(NP));
          if (MD<MINMD) {
            MD=MINMD;
            NP--;
          }
          nint2=0;
        }
      }
    } 
    else { // no room for new point
      nint1++;
      if (nint1>=NTRIALS) {
        MD/=(1+1.0/float(NP));
        if (MD<MINMD) {
          MD=MINMD;
          NP--;
        }
        // allow algorithm to find "good" points again
        THR=MAXTHR;
        nint1=0;
      }
    }
  }
  
  return i;
}

int NessimMesProper(int i) {
  if (NMP<=1) {
    int mP=-1;
    float dmP=dist(0, 0, width, height);
    for (int j=0; j<NP; j++) {
      if (usat[j]==0) {
        float jmP=dist(punts[i][0], punts[i][1], punts[j][0], punts[j][1]);
        if ((ALFAMD>=0.0) && (jmP<MINMD+ALFAMD*(MAXMD-MINMD))) { // eliminar punts massa propers
          ++removed;
          println("removed: "+removed);
          usat[j]=1;
        } else {
          if (jmP<dmP) {
            dmP=jmP;
            mP=j;
          }
        }
      }
    }
    return mP;
  } 
  else {
    for (int j=0; j<NMP; j++) {
      NmP[j]=-1;    
      NdmP[j]=dist(0, 0, width, height);
    }
    for (int j=0; j<NP; j++) {
      if (usat[j]==0) {
        float jmP=dist(punts[i][0], punts[i][1], punts[j][0], punts[j][1]);
        if ((ALFAMD>=0.0) && (jmP<MINMD+ALFAMD*(MAXMD-MINMD))) { // eliminar punts massa propers
          ++removed;
          println("removed: "+removed);
          usat[j]=1;
        } else {
          int k=NMP;
          while(k>0 && NdmP[k-1]>jmP) {
            k--;
          }
          if (k<NMP) {
            for (int l=0; l<(NMP-k)-1; l++) {
              NmP[(NMP-1)-l]=NmP[(NMP-1)-(l+1)];
              NdmP[(NMP-1)-l]=NdmP[(NMP-1)-(l+1)];
            }
            NmP[k]=j;
            NdmP[k]=jmP;
          }
        }
      }
    }
    return NmP[NMP-1];
  }
}

int fase=0;
int i=0;
int removed=0;

void draw() {
  if (fase==0) {
    i=creaPunt(i);
    if (i>=NP) {
      fase=1;
      background(#FFFFFF);
      
      /* volcar els punts */
      //Table taulaPunts;
      //
      //taulaPunts=createTable();
      //taulaPunts.addColumn("p");
      //taulaPunts.addColumn("x");
      //taulaPunts.addColumn("y");
      //for (int p=0; p<NP; p++) {
      //  TableRow novaFila = taulaPunts.addRow();
      //  novaFila.setInt("p", p+1);
      //  novaFila.setFloat("x", punts[p][0]);
      //  novaFila.setFloat("y", punts[p][1]);
      //}
      //saveTable(taulaPunts, "punts.csv");
    }
  } 
  else {
    if (inici!=-1) {
      stroke(#000000);
      usat[inici]=1;

      int seguent=NessimMesProper(inici);
      if (seguent!=-1) {
        float d=dist(punts[inici][0], punts[inici][1], punts[seguent][0], punts[seguent][1]);
        strokeWeight(SW/(1.0+log(1.0+d)));
        line(punts[inici][0], punts[inici][1], punts[seguent][0], punts[seguent][1]);
        //rect(punts[inici][0], punts[inici][1], punts[seguent][0]-punts[inici][0], punts[seguent][1]-punts[inici][1]);
      }
      inici=seguent;
    } 
    else {
      save(iName+"outlined.png");
      println("done!");
      noLoop();
    }
  }
}

