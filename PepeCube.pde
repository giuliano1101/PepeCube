/***************************************
 * Title: PepeCube
 * Author: Yubin Shi
 * Date: January 2025
 * 
 * Description: 
 * A meme-inspired puzzle game featuring Pepe the Frog.
 * This quirky take on the classic block-falling puzzle
 * combines Pepe's iconic face with traditional gameplay.
 * Complete with particle effects, sound effects, and
 * firework celebrations, it's a fun twist on a
 * classic format.
 ***************************************/

import processing.sound.*;

// Game Constants
final int COLS = 10;          // 10x10 square grid
final int ROWS = 10;          
final int BLOCK_SIZE = 130;   // 1300/10, make blocks fill the screen perfectly
final int GAME_X = 0;         // Start from left
final int GAME_Y = 0;         // Start from top
float scaleFactor = 1.0;  // Scale factor for window resizing
final int BASE_WIDTH = 1300;  // Original design width
final int BASE_HEIGHT = 1300; // Original design height

// Game Variables
PImage blockTexture;         
PImage gameOverImage;        
PImage victoryImage;        
int[][] grid;                
int[][] currentPiece;        
int currentX, currentY;      
int currentType;            
boolean gameOver;           
boolean isVictory = false;  
int linesCleared = 0;       
float gameOverAlpha = 0;    
float victoryAlpha = 0;     
float shakeAmount = 10;     
ArrayList<ParticleSystem> particleSystems;  
ArrayList<Firework> fireworks;
PImage backgroundImage;      // Title screen background image
boolean gameStarted = false; // Game start flag
float startTextAlpha = 255;  // Start text transparency
float startAlphaChange = -2; // Transparency change rate
SoundFile buttonSound;
SoundFile downSound;    // Block falling sound
SoundFile clearSound;   // Line clear sound
SoundFile crySound;     // Game over cry sound
SoundFile wuSound;      // Game over loop sound
SoundFile happySound;   // Victory loop sound
boolean isPlayingLoop = false;  // Control loop sound flag
SoundFile bgmTitle;    // Title screen BGM
SoundFile bgmGame;     // Gameplay BGM
boolean isPlayingGameOverSound = false;
float gameStartTime;  // Game start time
float gameEndTime;    // Game end time

// Tetromino shapes definition
int[][][] tetrominoes = {
  {{1,1,1,1}},
  {{1,1},
   {1,1}},
  {{0,1,0},
   {1,1,1}},
  {{1,0,0},
   {1,1,1}},
  {{0,0,1},
   {1,1,1}},
  {{0,1,1},
   {1,1,0}},
  {{1,1,0},
   {0,1,1}}
};

Button tryAgainButton;
Button quitButton;

void setup() {
  size(1300, 1300, JAVA2D);
  surface.setResizable(true);
  
  // Disable microphone input
  System.setProperty("java.awt.headless", "true");
  
  // Load all sounds
  buttonSound = new SoundFile(this, "button.wav");
  downSound = new SoundFile(this, "down.wav");
  clearSound = new SoundFile(this, "gua.wav");
  crySound = new SoundFile(this, "cry.wav");
  wuSound = new SoundFile(this, "wu.wav");
  happySound = new SoundFile(this, "happy.wav");
  
  // Load background music
  bgmTitle = new SoundFile(this, "bgm1.mp3");
  bgmGame = new SoundFile(this, "bgm2.mp3");
  
  // Set background music to loop
  bgmTitle.loop();
  
  // Load all images
  backgroundImage = loadImage("background.png");
  backgroundImage.resize(1200, 600);  // Initial size set to larger dimensions
  blockTexture = loadImage("pepeface.png");
  blockTexture.resize(BLOCK_SIZE, BLOCK_SIZE);
  gameOverImage = loadImage("sad.png");
  gameOverImage.resize(800, 800);
  victoryImage = loadImage("happy.png");
  victoryImage.resize(800, 800);
  
  int centerOffset = -100;
  tryAgainButton = new Button(width/2 - 180, height/2 + 450 + centerOffset, 150, 50, "Try Again");
  quitButton = new Button(width/2 + 30, height/2 + 450 + centerOffset, 150, 50, "Quit Game");
  
  resetGame();
}

void draw() {
  // Force window to maintain square shape
  if (width != height) {
    int size = min(width, height);
    surface.setSize(size, size);
    return;
  }
  
  // Calculate scale factor
  scaleFactor = width / float(BASE_WIDTH);
  
  background(0);
  
  // Apply scaling transformation to entire game
  pushMatrix();
  // Scale everything from the center
  translate(width/2, height/2);
  scale(scaleFactor);
  translate(-BASE_WIDTH/2, -BASE_HEIGHT/2);
  
  if (!gameStarted) {
    drawStartScreen();
  } else if (!gameOver && !isVictory) {
    drawGrid();
    drawCurrentPiece();
    
    for (int i = particleSystems.size() - 1; i >= 0; i--) {
      ParticleSystem ps = particleSystems.get(i);
      ps.update();
      ps.display();
      if (ps.isDead()) {
        particleSystems.remove(i);
      }
    }
    
    if (frameCount % 30 == 0) {
      moveDown();
    }
  } else if (isVictory) {
    drawVictory();
  } else {
    drawGameOver();
  }
  
  popMatrix();
}

// ... [Here continue the other functions, including Button class, Particle class, etc.] ... 

class Button {
  float x, y, w, h;
  String text;
  
  Button(float x, float y, float w, float h, String text) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.text = text;
  }
  
  boolean isMouseOver() {
    float mx = getScaledMouseX();
    float my = getScaledMouseY();
    return isMouseOver(mx, my);
  }
  
  boolean isMouseOver(float mx, float my) {
    return mx >= x && mx <= x + w && 
           my >= y && my <= y + h;
  }
  
  void display(float alpha) {
    if (isMouseOver()) {
      fill(100, 255 * alpha);  // Gray when mouse is over
    } else {
      fill(0, 255 * alpha);    // Normal color is black
    }
    stroke(255, 255 * alpha);  // White border
    strokeWeight(2);  // Thick border
    rect(x, y, w, h, 10);  // Rounded rectangle
    
    fill(255, 255 * alpha);    // White text
    textAlign(CENTER, CENTER);
    textSize(24);  // Slightly smaller font size
    text(text, x + w/2, y + h/2);
  }
  
  void display() {
    display(1.0);  // Default fully opaque
  }
}

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  PImage img;
  float size;
  
  Particle(float x, float y, PImage img) {
    this.img = img;
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(2, 5));
    acceleration = new PVector(0, 0.1);
    lifespan = 255.0;
    size = random(10, 30);
  }

  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 5.0;
  }

  void display() {
    tint(255, lifespan);
    imageMode(CENTER);
    image(img, position.x, position.y, size, size);
    imageMode(CORNER);
    noTint();
  }
  
  boolean isDead() {
    return lifespan < 0;
  }
}

class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;
  PImage img;
  
  ParticleSystem(float x, float y, PImage img) {
    origin = new PVector(x, y);
    this.img = img;
    particles = new ArrayList<Particle>();
    for (int i = 0; i < 20; i++) {
      particles.add(new Particle(x, y, img));
    }
  }

  void update() {
    for (int i = particles.size() - 1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.update();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }

  void display() {
    for (Particle p : particles) {
      p.display();
    }
  }
  
  boolean isDead() {
    return particles.isEmpty();
  }
}

class FireworkParticle {
  PVector position;
  PVector velocity;
  float lifespan;
  color col;
  
  FireworkParticle(float x, float y, color c) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(3, 8));
    lifespan = 255.0;
    col = c;
  }

  void update() {
    position.add(velocity);
    velocity.mult(0.98);
    lifespan -= 4.0;
  }

  void display() {
    if (lifespan > 0) {
      stroke(col, lifespan);
      strokeWeight(4);
      point(position.x, position.y);
    }
  }
  
  boolean isDead() {
    return lifespan < 0;
  }
}

class Firework {
  ArrayList<FireworkParticle> particles;
  boolean isDead;
  
  Firework(float x, float y) {
    particles = new ArrayList<FireworkParticle>();
    color[] colors = {
      color(255, 0, 0),    // Red
      color(0, 255, 0),    // Green
      color(0, 0, 255),    // Blue
      color(255, 255, 0),  // Yellow
      color(255, 0, 255)   // Purple
    };
    
    for (int i = 0; i < 100; i++) {
      color randomColor = colors[int(random(colors.length))];
      particles.add(new FireworkParticle(x, y, randomColor));
    }
    isDead = false;
  }

  void update() {
    for (int i = particles.size() - 1; i >= 0; i--) {
      FireworkParticle p = particles.get(i);
      p.update();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
    if (particles.isEmpty()) {
      isDead = true;
    }
  }

  void display() {
    for (FireworkParticle p : particles) {
      p.display();
    }
  }
} 

void resetGame() {
  grid = new int[ROWS][COLS];
  gameOver = false;
  isVictory = false;
  linesCleared = 0;
  victoryAlpha = 0;
  gameOverAlpha = 0;
  particleSystems = new ArrayList<ParticleSystem>();
  fireworks = new ArrayList<Firework>();
  
  // Stop all sounds
  if (wuSound.isPlaying()) wuSound.stop();
  if (happySound.isPlaying()) happySound.stop();
  if (crySound.isPlaying()) crySound.stop();
  isPlayingGameOverSound = false;
  isPlayingLoop = false;
  
  // If not in title screen, ensure game background music is playing
  if (gameStarted && !bgmGame.isPlaying()) {
    bgmTitle.stop();
    bgmGame.loop();
  }
  
  // Reset timer
  gameStartTime = millis();
  
  spawnNewPiece();
} 

void drawGrid() {
  // Draw placed blocks
  for (int row = 0; row < ROWS; row++) {
    for (int col = 0; col < COLS; col++) {
      if (grid[row][col] == 1) {
        image(blockTexture, 
              GAME_X + col * BLOCK_SIZE, 
              GAME_Y + row * BLOCK_SIZE);
      }
    }
  }
  
  // Draw grid lines
  stroke(40);  // Dark gray grid lines
  for (int row = 0; row <= ROWS; row++) {
    line(GAME_X, GAME_Y + row * BLOCK_SIZE, 
         GAME_X + COLS * BLOCK_SIZE, GAME_Y + row * BLOCK_SIZE);
  }
  for (int col = 0; col <= COLS; col++) {
    line(GAME_X + col * BLOCK_SIZE, GAME_Y,
         GAME_X + col * BLOCK_SIZE, GAME_Y + ROWS * BLOCK_SIZE);
  }
}

void drawCurrentPiece() {
  if (currentPiece != null) {
    for (int row = 0; row < currentPiece.length; row++) {
      for (int col = 0; col < currentPiece[row].length; col++) {
        if (currentPiece[row][col] == 1) {
          image(blockTexture,
                GAME_X + (currentX + col) * BLOCK_SIZE,
                GAME_Y + (currentY + row) * BLOCK_SIZE);
        }
      }
    }
  }
}

void drawGameOver() {
  if (gameOverAlpha < 255) {
    gameOverAlpha += 5;
  }
  
  float shakeX = random(-shakeAmount, shakeAmount) * (gameOverAlpha/255);
  float shakeY = random(-shakeAmount, shakeAmount) * (gameOverAlpha/255);
  
  imageMode(CENTER);
  tint(255, gameOverAlpha);
  image(gameOverImage, 
        BASE_WIDTH/2 + shakeX, 
        BASE_HEIGHT/2 - 100 + shakeY);
  imageMode(CORNER);
  noTint();
  
  pushStyle();
  float buttonAlpha = map(gameOverAlpha, 0, 255, 0, 1);
  if (buttonAlpha > 0) {
    tryAgainButton.display(buttonAlpha);
    quitButton.display(buttonAlpha);
  }
  popStyle();
}

void drawVictory() {
  if (victoryAlpha < 255) {
    victoryAlpha += 5;
  }
  
  float shakeX = random(-shakeAmount, shakeAmount) * (victoryAlpha/255);
  float shakeY = random(-shakeAmount, shakeAmount) * (victoryAlpha/255);
  
  imageMode(CENTER);
  tint(255, victoryAlpha);
  image(victoryImage, 
        BASE_WIDTH/2 + shakeX, 
        BASE_HEIGHT/2 - 100 + shakeY);
  imageMode(CORNER);
  noTint();
  
  if (random(1) < 0.05) {
    fireworks.add(new Firework(random(BASE_WIDTH), random(BASE_HEIGHT)));
  }
  
  for (int i = fireworks.size() - 1; i >= 0; i--) {
    Firework f = fireworks.get(i);
    f.update();
    f.display();
    if (f.isDead) {
      fireworks.remove(i);
    }
  }
  
  pushStyle();
  textAlign(CENTER);
  textSize(32);
  fill(255, victoryAlpha);
  float timeSpent = (gameEndTime - gameStartTime) / 1000;
  text("You Spend: " + nf(timeSpent, 0, 1) + " SECOND", BASE_WIDTH/2, BASE_HEIGHT - 100);
  popStyle();
  
  pushStyle();
  float buttonAlpha = map(victoryAlpha, 0, 255, 0, 1);
  if (buttonAlpha > 0) {
    tryAgainButton.display(buttonAlpha);
    quitButton.display(buttonAlpha);
  }
  popStyle();
}

void moveDown() {
  currentY++;
  if (checkCollision()) {
    currentY--;
    mergePiece();
    spawnNewPiece();
  } else {
    downSound.play();  // Play block falling sound
  }
}

void mergePiece() {
  for (int row = 0; row < currentPiece.length; row++) {
    for (int col = 0; col < currentPiece[row].length; col++) {
      if (currentPiece[row][col] == 1) {
        grid[currentY + row][currentX + col] = 1;
      }
    }
  }
  checkLines();
}

void checkLines() {
  for (int row = ROWS-1; row >= 0; row--) {
    boolean isLineFull = true;
    for (int col = 0; col < COLS; col++) {
      if (grid[row][col] == 0) {
        isLineFull = false;
        break;
      }
    }
    if (isLineFull) {
      removeLine(row);
      row++;  // Recheck current row
      linesCleared++;
      if (linesCleared >= 10) {  // ***** Win condition: Clear 10 lines to win *****
        isVictory = true;
        // Record end time
        gameEndTime = millis();
        // Stop game background music
        bgmGame.stop();
        // Stop previous loop sound (if any)
        if (wuSound.isPlaying()) wuSound.stop();
        if (happySound.isPlaying()) happySound.stop();
        // Start loop playing victory sound
        happySound.loop();
        isPlayingLoop = true;
      }
    }
  }
}

void removeLine(int row) {
  clearSound.play();  // Play line clear sound
  
  // Create particle system for each block in the line
  for (int col = 0; col < COLS; col++) {
    if (grid[row][col] == 1) {
      float x = GAME_X + col * BLOCK_SIZE + BLOCK_SIZE/2;
      float y = GAME_Y + row * BLOCK_SIZE + BLOCK_SIZE/2;
      particleSystems.add(new ParticleSystem(x, y, blockTexture));
    }
  }
  
  for (int y = row; y > 0; y--) {
    for (int col = 0; col < COLS; col++) {
      grid[y][col] = grid[y-1][col];
    }
  }
  for (int col = 0; col < COLS; col++) {
    grid[0][col] = 0;
  }
}

void spawnNewPiece() {
  currentType = int(random(tetrominoes.length));
  currentPiece = tetrominoes[currentType];
  currentX = COLS/2 - currentPiece[0].length/2;
  currentY = 0;
  
  if (checkCollision()) {
    gameOver = true;
    // Stop game background music
    bgmGame.stop();
    // Stop all previous sounds
    if (wuSound.isPlaying()) wuSound.stop();
    if (happySound.isPlaying()) happySound.stop();
    if (crySound.isPlaying()) crySound.stop();
    
    // Play both game over sounds at once
    crySound.play();
    wuSound.play();
  }
}

boolean checkCollision() {
  for (int row = 0; row < currentPiece.length; row++) {
    for (int col = 0; col < currentPiece[row].length; col++) {
      if (currentPiece[row][col] == 1) {
        int nextX = currentX + col;
        int nextY = currentY + row;
        
        if (nextX < 0 || nextX >= COLS || nextY >= ROWS) return true;
        if (nextY >= 0 && grid[nextY][nextX] == 1) return true;
      }
    }
  }
  return false;
}

void mousePressed() {
  float mx = getScaledMouseX();
  float my = getScaledMouseY();
  
  if (gameOver || isVictory) {
    if (tryAgainButton.isMouseOver(mx, my)) {
      buttonSound.play();
      resetGame();
    } else if (quitButton.isMouseOver(mx, my)) {
      buttonSound.play();
      exit();
    }
  }
}

void keyPressed() {
  if (!gameStarted) {
    if (keyCode == ENTER) {
      buttonSound.play();
      gameStarted = true;
      // Switch background music
      bgmTitle.stop();
      bgmGame.loop();
      resetGame();
    }
    return;
  }
  
  if (!gameOver && !isVictory) {
    if (keyCode == LEFT) {
      buttonSound.play();
      currentX--;
      if (checkCollision()) currentX++;
    }
    else if (keyCode == RIGHT) {
      buttonSound.play();
      currentX++;
      if (checkCollision()) currentX--;
    }
    else if (keyCode == DOWN) {
      downSound.play();  // Use block falling sound instead of button sound
      moveDown();
    }
    else if (keyCode == UP) {
      buttonSound.play();
      rotatePiece();
    }
  }
}

void rotatePiece() {
  int[][] rotated = new int[currentPiece[0].length][currentPiece.length];
  for (int row = 0; row < currentPiece.length; row++) {
    for (int col = 0; col < currentPiece[row].length; col++) {
      rotated[col][currentPiece.length-1-row] = currentPiece[row][col];
    }
  }
  
  int[][] temp = currentPiece;
  currentPiece = rotated;
  if (checkCollision()) {
    currentPiece = temp;
  }
}

void drawStartScreen() {
  // Draw background image
  imageMode(CENTER);
  pushStyle();
  rectMode(CENTER);
  float imgWidth = BASE_WIDTH * 0.9;  // 90% of base width
  float imgHeight = BASE_HEIGHT * 0.45;  // 45% of base height
  
  // Create a PGraphics for rounded corners
  PGraphics pg = createGraphics(int(imgWidth), int(imgHeight));
  pg.beginDraw();
  pg.background(0, 0);
  pg.smooth();
  
  pg.fill(255);
  pg.noStroke();
  pg.rect(0, 0, imgWidth, imgHeight, 30);
  
  pg.imageMode(CENTER);
  pg.image(backgroundImage, imgWidth/2, imgHeight/2);
  pg.endDraw();
  
  // Draw final image at 1/3 of base height
  image(pg, BASE_WIDTH/2, BASE_HEIGHT/3);
  popStyle();
  imageMode(CORNER);
  
  // Calculate text positions relative to BASE_HEIGHT
  float imageBottom = BASE_HEIGHT/3 + imgHeight/2;
  float startTextY = BASE_HEIGHT - 150;
  float controlsY = (imageBottom + startTextY) / 2;
  
  // Draw controls title
  fill(255);
  textAlign(CENTER);
  textSize(40);
  PFont boldFont = createFont("Arial-Bold", 40);
  textFont(boldFont);
  text("Controls", BASE_WIDTH/2, controlsY - 50);
  
  // Draw button instructions
  textSize(30);
  float textX = BASE_WIDTH/2 - 150;
  float spacing = 40;
  
  textAlign(LEFT);
  text("←  →    Move Left/Right", textX, controlsY);
  text("↑        Rotate", textX, controlsY + spacing);
  text("↓        Speed Up", textX, controlsY + spacing * 2);
  
  // Draw flashing start prompt
  startTextAlpha += startAlphaChange;
  if (startTextAlpha <= 0 || startTextAlpha >= 255) {
    startAlphaChange *= -1;
  }
  
  textAlign(CENTER);
  textSize(36);
  fill(255, startTextAlpha);
  text("Press ENTER to Start", BASE_WIDTH/2, startTextY);
} 

float getScaledMouseX() {
  // Transform mouse coordinates to game coordinate system
  return (mouseX - width/2) / scaleFactor + BASE_WIDTH/2;
}

float getScaledMouseY() {
  // Transform mouse coordinates to game coordinate system
  return (mouseY - height/2) / scaleFactor + BASE_HEIGHT/2;
} 