import java.util.*;

String fileName = "normal2.config";
int numSamples = 10;

PShader shader;

float previousTime = 0.0;

boolean mouseDragged = false;
boolean combineSamples = false;
boolean drawNormals = false;
boolean useNormalMaps = true;

PVector lastMousePosition;
float mouseClickState = 0.0;

List<Float> data = new ArrayList();
List<Integer> faces = new ArrayList();
Scanner scanner = null;

float[] cameraPosition = {0, .4, 0};
float[] cameraRotation = {0, 0};
float[] cameraStartRotation = {0, 0};

int sampleNum = 0;

int[] prev = new int[width * height * 3];

void setup() {
   lastMousePosition = new PVector(float(mouseX), float(mouseY));
   size(640, 480, P2D);
   shader = loadShader("zzzz.glsl");

   shader.set("numSamples", numSamples);
   shader.set("drawNormals", drawNormals);
   shader.set("useNormalMaps", useNormalMaps);
   //shader.set("enableRotation", false);
   shader.set("iResolution", float(width), float(height), 0.0);

   try {
      scanner = new Scanner(new File(sketchPath() + "/" + fileName));
   }
   catch (Exception e) {
      e.printStackTrace();
   }
   boolean rotSet = false;
   boolean posSet = false;
   boolean fovSet = false;
   while (scanner.hasNextLine()) {
      String line = scanner.nextLine();
      if (line.startsWith(";")) {
         continue;
      } else if (line.contains("plane")) {
         faces.add(data.size());
         parsePlane();
      } else if (line.contains("sphere")) {
         faces.add(data.size());
         parseSphere();
      } else if (line.contains("quad")) {
         faces.add(data.size());
         parseQuad();
      } else if (line.contains("cameraPos")) {
         String[] point = line.trim().split(":")[1].trim().split(",");
         cameraPosition = new float[]{Float.parseFloat(point[0]), Float.parseFloat(point[1]), Float.parseFloat(point[2])};
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
         posSet = true;
      } else if (line.contains("cameraRotation")) {
         String[] point = line.trim().split(":")[1].trim().split(",");
         cameraRotation = new float[]{Float.parseFloat(point[0]), Float.parseFloat(point[1])};
         cameraStartRotation = new float[] {cameraRotation[0], cameraRotation[1]};
         shader.set("cameraRotation", cameraRotation[0], cameraRotation[1]);
         rotSet = true;
      } else if (line.contains("fovLength")) {
         String num = line.trim().split(":")[1].trim();
         shader.set("fovLength", Float.parseFloat(num));
         fovSet = true;
      }
   }
   if (!rotSet) {
      shader.set("cameraRotation", 0., 0.);
   }
   if (!posSet) {
      shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
   }
   if (!fovSet) {
      shader.set("fovLength", 1.);
   }
   int[] facesArr = new int[faces.size()];
   float[] dataArr = new float[data.size()];
   for (int i = 0; i < facesArr.length; i++) {
      facesArr[i] = faces.get(i);
   }
   for (int i = 0; i < dataArr.length; i++) {
      dataArr[i] = data.get(i);
   }
   shader.set("faces", facesArr);
   shader.set("data", dataArr);
}

float mouseStartX = 0;
float mouseStartY = 0;

void draw() {
   if (!combineSamples) {
      if (mousePressed) {
         lastMousePosition.set(float(mouseX), float(mouseY));
         if (mouseClickState == 0.) {
            mouseStartX = float(mouseX);
            mouseStartY = float(mouseY);
         }
         cameraRotation[0] = cameraStartRotation[0] - (float(mouseX) - mouseStartX) / 500;
         cameraRotation[1] = cameraStartRotation[1] + (float(mouseY) - mouseStartY) / 500;
         mouseClickState = 1.0;
      } else {
         if (mouseClickState == 1.) {
            cameraStartRotation[0] = cameraRotation[0];
            cameraStartRotation[1] = cameraRotation[1];
         }
         mouseClickState = 0.0;
      }
   }
   //shader.set("iMouse", lastMousePosition.x, lastMousePosition.y, mouseClickState, mouseClickState);
   shader.set("cameraRotation", cameraRotation[0], cameraRotation[1]);
   float currentTime = millis()/1000.0;
   shader.set("iTime", currentTime);

   shader(shader);
   rect(0, 0, width, height);
   resetShader();
   if (combineSamples) {
      loadPixels();
      sampleNum++;
      for (int i = 0; i < width * height; i++) {
         int col = pixels[i];
         int ind = i * 3;
         prev[ind] += col >> 16 & 0xff;
         prev[ind + 1] += col >> 8 & 0xff;
         prev[ind + 2] += col & 0xff;
         int r = prev[ind] / sampleNum;
         int g = prev[ind + 1] / sampleNum;
         int b = prev[ind + 2] / sampleNum;
         pixels[i] = color(r, g, b);
      }
      updatePixels();
      System.out.println(sampleNum);
   }
}
void resetBuffer() {
  sampleNum = 0;
  prev = new int[width * height * 3];
}
void keyPressed() {
   if (key >= 'a' && key <= 'z') {
      if (key == 'w') {
         cameraPosition[1] += .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 's') {
         cameraPosition[1] -= .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 'a') {
         cameraPosition[0] -= .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 'd') {
         cameraPosition[0] += .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 'r') {
         cameraPosition[2] += .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 'f') {
         cameraPosition[2] -= .1;
         shader.set("cameraPos", cameraPosition[0], cameraPosition[1], cameraPosition[2]);
      }
      if (key == 'g') {
         if (!drawNormals) {
            combineSamples = !combineSamples;
            resetBuffer();
         }
      }
      if (key == 'n') {
         if (drawNormals) {
            shader.set("numSamples", numSamples);
            shader.set("drawNormals", false);
         } else {
            shader.set("numSamples", 1);
            shader.set("drawNormals", true);
            combineSamples = false;
         }
         drawNormals = !drawNormals;
      }
      if (key == 't') {
         saveFrame("output.png");
      }
      if (key == 'y') {
        useNormalMaps = !useNormalMaps;
        shader.set("useNormalMaps", useNormalMaps);
        resetBuffer();
      }
   }
}

void parsePlane() {
   data.add(0.);
   addPoint(scanner.nextLine());
   addPoint(scanner.nextLine());
   addMaterial();
}
void parseSphere() {
   data.add(1.);
   addPoint(scanner.nextLine());
   addFloat(scanner.nextLine());
   addMaterial();
}
void parseQuad() {
   data.add(2.);
   addPoint(scanner.nextLine());
   addPoint(scanner.nextLine());
   addPoint(scanner.nextLine());
   addPoint(scanner.nextLine());
   addMaterial();
}

void addPoint(String pointS) {
   String[] point = pointS.trim().split(":")[1].trim().split(",");
   for (int i = 0; i < point.length; i++) {
      data.add(Float.parseFloat(point[i]));
   }
}

void addFloat(String line) {
   data.add(Float.parseFloat(line.trim().split(":")[1].trim()));
}

static int textureI = 1;

void setTexture(String name, int index) {
   data.set(index, (float) textureI);
   shader.set("texture" + textureI, loadImage(name));
   textureI++;
}

void addMaterial() {
   String mat = scanner.nextLine().trim().split(":")[1].trim();
   if (mat.equals("diffuse")) {
      data.add(1.);
      addPoint(scanner.nextLine());
   } else if (mat.equals("emission")) {
      data.add(0.);
      addPoint(scanner.nextLine());
   } else if (mat.equals("diffuse/specular")) {
      data.add(2.);
      addPoint(scanner.nextLine());
      addFloat(scanner.nextLine());
   } else if (mat.equals("specular")) {
      data.add(3.);
      addPoint(scanner.nextLine());
   } else if (mat.equals("diffuse/textured")) {
      data.add(4.);
      int textureLocIndex = data.size();
      for (int i = 0; i < 3; i++) {
         data.add(-1.);
      }
      String textures = scanner.nextLine().trim().split(":")[1].trim();
      if (textures.contains("color")) {
         setTexture(scanner.nextLine().trim().split(":")[1].trim(), textureLocIndex + 0);
      }
      if (textures.contains("normal")) {
         setTexture(scanner.nextLine().trim().split(":")[1].trim(), textureLocIndex + 1);
      }
      if (textures.contains("specular")) {
         setTexture(scanner.nextLine().trim().split(":")[1].trim(), textureLocIndex + 2);
      }
   }
}
