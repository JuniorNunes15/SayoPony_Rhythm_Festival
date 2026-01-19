import processing.sound.*;
import java.util.*;
import processing.serial.*;
Serial serialPort;

SoundFile music;
SoundFile hitSoundPerfect, hitSoundGood, hitSoundMiss, holdTick;

ArrayList<Note> notes;
Chart chart;

boolean running = false;
boolean editing = false;
boolean paused = false;
boolean winning = false;
boolean gameOver = false;

float hitLineY;
int columns = 5;
int[] keys = { 'a', 's', 'd', 'f', 'g' };

// Listas das músicas
String[] songList = { "Rakuen", "Hoshi_no_Tabiji", "Houkago_Escape", "Shion", "Uchu_Katasumi"};
String[] songListName = {"Rakuen", "Hoshi no Tabiji", "Houkago Escape", "Shion", "Uchu no Katasumi"}; // Nome real para aparecer na tela
int selectedSongIndex = 0;
String currentSongName = "";

float animatedIndex = 0;
float animatedIndexPos;
float animatedIndexVisual;

float noteSpeed = 800.0; 
float spawnY = -80;
float travelDistance; 
float travelTime; 

// Score
int score = 0;
int combo = 0;
int maxCombo = 0;
int life = 100;
int hitWindowPerfectMs = 80;
int hitWindowGoodMs = 160;
int lifeStreak = 0;
int hitsToRecover = 20;


// Snapping para criação de charts dentro do jogo
int snapping = 16;
boolean showEditorGrid = true;
ArrayList<HitEffect> effects;

// Estados
final int TELAINICIAL = 0;
final int MENU = 1;
final int JOGO = 2;
final int RESULTADO = 3;
final int GAMEOVER = 4;

// Estado inicial do jogo
int estado = TELAINICIAL;

// variaveis de transicao
int proximoEstado = TELAINICIAL;
float fadeAlpha = 0;
float blurAmount = 0;
boolean emTransicao = false;
boolean fadeIn = false;

SoundFile menuMusic;
boolean menuMusicPlaying = false; 

class SongImage {
  String name;
  PImage normal;
  PImage selected;

  SongImage(String name) {
    this.name = name;
    normal = loadImage("menu/" + name + "_normal.png"); // imagens normais das musicas quando não estão selecionadas
    selected = loadImage("menu/" + name + "_selected.png"); // imagens das musicas quando estão selecionadas
  }
}

SongImage[] songImages;

void gradientBG(color c1, color c2) {
  for (int i = 0; i < height; i++) {
    float t = map(i, 0, height, 0, 1);
    stroke(lerpColor(c1, c2, t));
    line(0, i, width, i);
  }
}

// imagens das notas
PImage[] noteImgs = new PImage[5];
PImage backgroundImage;
PImage hitPerfect, hitGood, hitMiss;

PFont gameFont;

boolean isCountdown = false;
float countdownStartTime = 0;
int countdownValue = 3;
float songStartTime = 0;

boolean songVolume = false;


void setup() {
  size(900, 700);
  frameRate(60);
  
  gameFont = createFont("fonts/Daydream.otf", 32);
  textFont(gameFont);
  
  // sprite das notas
  noteImgs[0] = loadImage("data/star1_5x.png");
  noteImgs[1] = loadImage("data/star1_5x.png");
  noteImgs[2] = loadImage("data/star1_5x.png");
  noteImgs[3] = loadImage("data/star1_5x.png");
  noteImgs[4] = loadImage("data/star1_5x.png");
  
  backgroundImage = loadImage("data/pony15x.png");
  
  // Música da tela inicial/menu
  menuMusic = new SoundFile(this, "data/musics/Romance.mp3");
  
  
  hitPerfect = loadImage("star2_5x.png");
  hitGood = loadImage("star2_5x.png");
  hitMiss = loadImage("star2_5x.png");

  animatedIndex = selectedSongIndex;
  animatedIndexPos    = selectedSongIndex;
  animatedIndexVisual = selectedSongIndex;
  
  hitLineY = height - 150;
  travelDistance = hitLineY - spawnY;
  travelTime = travelDistance / noteSpeed;

  notes = new ArrayList<Note>();
  chart = new Chart();
  effects = new ArrayList<HitEffect>();
  
  // Pegar o serial port
  printArray(Serial.list());
  //serialPort = new Serial(this, Serial.list()[0], 9600);
  //serialPort.clear();

  textAlign(CENTER, CENTER);
  textSize(16);
  
  // Carregar imagens das músicas
  songImages = new SongImage[songList.length];
  for (int i = 0; i < songList.length; i++) {
    songImages[i] = new SongImage(songList[i]);
  }
}

// Quando conectado a um arduino, transforma os botões passados nos botões do jogo
void pressFromArduino(int n) {
  char k = ' ';

  switch(n) {
    case 1: k = 'a'; break;
    case 2: k = 's'; break;
    case 3: k = 'd'; break;
    case 4: k = 'f'; break;
    case 5: k = 'g'; break;
  }

  key = k;
  keyPressed();
}

//===============================TELAS PRINCIPAIS======================================================
void draw() {
  menuMusic.amp(0.3);
  //tocar musica de fundo
  if (estado < 2 && !editing) {
    if (!menuMusicPlaying) {
      menuMusic.play();
      menuMusicPlaying = true;  
    }
    if (!menuMusic.isPlaying()) {
      menuMusic.play();
    }
  }
  if (estado >= 2) {
    menuMusic.stop();
    menuMusicPlaying = false;
  }
  
  if (estado == TELAINICIAL) {
    drawTelaInicial();
  }
  if (estado == MENU) {
    drawMenu();
  }
  if (estado == RESULTADO) {
    drawWinning();
  }
  if (estado == GAMEOVER) {
    drawGameOver();
  }
  if (emTransicao) {
    drawTransicaoBlur();
  }
  if (isCountdown) {
    drawCountdown();
    return;
  }


  if (running) {
    if (!paused) updateGame();
    drawGame();
  } else if (editing) {
    if (!paused) updateEditor();
    drawEditor();
  }

  for (int i = effects.size()-1; i >= 0; i--) {
    effects.get(i).update();
    effects.get(i).draw();
    if (effects.get(i).isDone()) effects.remove(i);
  }
  
  // Conexão com o arduino
  /*while (serialPort.available() > 0) {
    String msg = serialPort.readStringUntil('\n');
    if (msg != null) {
        msg = msg.trim();
        if (msg.length() > 0 && Character.isDigit(msg.charAt(0))) {
            int n = int(msg);
            pressFromArduino(n);
        }
    }
  }*/
}

// Tela Inicial
void drawTelaInicial() {
  // Fundo em gradiente simples (céu pastel)
  background(230, 235, 255);

  noStroke();
  for (int i = 0; i < height; i += 2) {
    float inter = map(i, 0, height, 0, 1);
    int c = lerpColor(
      color(255, 235, 245), // rosa claro
      color(220, 230, 255), // azul claro
      inter
    );
    fill(c);
    rect(width / 2, i, width, 2);
  }

  textAlign(CENTER);
  imageMode(CENTER);

  float centerX = width / 2;
  float centerY = height / 2;

  // Animação suave
  float pulse = sin(frameCount * 0.04) * 6;

  // TÍTULO
  fill(80, 90, 130); // azul acinzentado
  textSize(30);
  text("SAYOPONY RHYTHM FESTIVAL", centerX, centerY - 190 + pulse);

  textSize(20);
  fill(120, 130, 160);
  text("Rhythm Game", centerX, centerY - 105);

  // LINHA DECORATIVA
  stroke(180, 160, 200, 120);
  line(centerX - 160, centerY - 80, centerX + 160, centerY - 80);
  noStroke();

  // TEXTO DE AÇÃO
  float fade = map(sin(frameCount * 0.06), -1, 1, 120, 200);
  fill(90, 100, 140, fade);
  textSize(22);
  text("Pressione ENTER para iniciar", centerX, centerY + 20);
  
  // TRIÂNGULO
  float triPulse = sin(frameCount * 0.06) * 3;
  float triX = centerX;
  float triY = centerY + 150 + triPulse;
  float triSize = 18;
  noStroke();
  fill(220, 90, 100, 180); // vermelho rosado, suave
  triangle(
    triX,           triY - triSize,
    triX - triSize, triY + triSize,
    triX + triSize, triY + triSize
  );

  // TEXTO SECUNDÁRIO
  fill(140, 150, 180);
  textSize(16);
  text("Romance de Sayonara Ponytail ", centerX, height - 60);
}

// Menu principal
void drawMenu() {
  image(backgroundImage, 450, 350, 900, 700);
  //background(230, 235, 255);
  // FUNDO EM GRADIENTE PASTEL
  /*noStroke();
  for (int i = 0; i < height; i += 2) {
    float inter = map(i, 0, height, 0, 1);
    int c = lerpColor(
      color(255, 235, 245), // rosa pastel
      color(220, 230, 255), // azul pastel
      inter
    );
    fill(c);
    rect(width / 2, i, width, 2);
  }*/

  // Movimento suave APENAS para posição
  animatedIndexPos = lerp(animatedIndexPos, selectedSongIndex, 0.12);

  imageMode(CENTER);
  textAlign(CENTER);

  float centerY = height / 2;
  float spacing = 150;
  int maxOffset = max(selectedSongIndex, songList.length - 1 - selectedSongIndex);

  // DESENHO DAS MÚSICAS
  for (int d = maxOffset; d >= 0; d--) {
    for (int i = 0; i < songList.length; i++) {
      int offset = i - selectedSongIndex;
      if (abs(offset) != d) continue;
      
      float y = centerY + (i - animatedIndexPos) * spacing;
      float dist = abs(offset);
      float scale = map(dist, 0, 3, 0.30, 0.18);
      scale = constrain(scale, 0.18, 0.30);
      
      float alpha = map(dist, 0, 3, 255, 110);
      alpha = constrain(alpha, 110, 255);
      
      boolean sel = (offset == 0);
      PImage img = sel ? songImages[i].selected : songImages[i].normal;

      if (img != null) {
        tint(255, alpha);
        image(
        img,
        width / 2,
        y,
        img.width * scale,
        img.height * scale
        );
        noTint();
    
        // NOME DA MÚSICA SELECIONADA
        if (sel) {
          textAlign(CENTER);
          textSize(26);
        
          String name = songListName[i];
        
          float textX = width / 2;
          float textY = y + 130;
        
          float paddingX = 5;
          float paddingY = 10;
        
          float tw = textWidth(name);
          float th = 26;
        
          // caixa de fundo
          noStroke();
          fill(40, 40, 40, 190);
          rectMode(CENTER);
          rect(
            textX - paddingX,
            textY - paddingY,
            tw + paddingX*5,
            th + paddingY*3,
            8
          );
        
          // texto com leve brilho estilo UI de jogo
          fill(255, 200, 220);
          text(name, textX + 2, textY + 2);
          fill(255);
          text(name, textX, textY);
          rectMode(CORNER);
        }
      }
      else {
        fill(90, 100, 140, alpha);
        text(songList[i], width / 2, y);
      }
    }
  }

  // PAINEL FIXO (FRENTE)
  textAlign(CENTER);
  noStroke();
  fill(255); // painel claro e translúcido
  rect(0, 0, width, 50);

  // TEXTO (TOPO ABSOLUTO)
  fill(255);
  textSize(40);
  textSize(18);
  fill(0);
  text("Use SETAS para escolher a musica e Enter para Jogar", width / 2, 30);
}

// Game Over
void drawGameOver() {
  //image(backgroundImage, 450, 350, 900, 700);
  fill(255);
  textSize(40);
  text("VOCE PERDEU", width/2, height/2);
  textSize(18);
  fill(180);
  text("Pressione BACKSPACE para voltar pro menu.", width/2, height - 60);
  text("Pressione R para tentar novamente.", width/2, height - 20);
}

// Terminar a musica
void drawWinning() {
  //background(20, 20, 30);
  textAlign(CENTER);
  fill(255);
  float centerX = width / 2;
  float centerY = height / 2;

  // Título
  textSize(40);
  text("MUSICA CONCLUIDA", centerX, centerY - 120);

  // Bloco de score
  textSize(26);
  text("Song  " + currentSongName, centerX, centerY - 80);
  text("Score  " + score,    centerX, centerY - 40);
  text("Combo  " + combo,    centerX, centerY);
  text("Max Combo  " + maxCombo, centerX, centerY + 40);
  text("Life  " + life,      centerX, centerY + 80);

  // Rodapé
  textSize(18);
  fill(180);
  text("Pressione BACKSPACE para voltar ao menu.", centerX, height - 60);
}

// Transição de tela
void iniciarTransicao(int novoEstado) {
  if (emTransicao) return;
  proximoEstado = novoEstado;
  emTransicao = true;
  fadeIn = false;
  fadeAlpha = 0;
}

void drawTransicaoBlur() {
  // BLUR
  filter(BLUR, blurAmount);

  // OVERLAY ESCURO
  noStroke();
  fill(200, 210, 255, fadeAlpha);
  rect(0, 0, width, height);

  if (!fadeIn) {
    fadeAlpha += 25;
    blurAmount += 0.6;
    if (fadeAlpha >= 255) {
      fadeAlpha = 255;
      blurAmount = 12;  // blur máximo
      estado = proximoEstado;
      fadeIn = true;
    }
  } 
  else {
    fadeAlpha -= 25;
    blurAmount -= 0.6;
    if (fadeAlpha <= 0) {
      fadeAlpha = 0;
      blurAmount = 0;
      emTransicao = false;
    }
  }
}
//=====================================================================================

//===============================BOTÕES======================================================
void keyPressed() {
  if(estado == TELAINICIAL) {
    if (keyCode == ENTER || key == '\n') {
      iniciarTransicao(MENU); //estado = MENU;
    }
  }
  if (estado == MENU) {
    if (keyCode == UP) selectedSongIndex = max(0, selectedSongIndex-1);
    if (keyCode == DOWN) selectedSongIndex = min(songList.length-1, selectedSongIndex+1);
    if (keyCode == ENTER || key == '\n') {
      isCountdown = true;
      countdownStartTime = millis() / 1000.0;
      countdownValue = 3;
      //estado = JOGO;
      ///startGame(songList[selectedSongIndex], songListName[selectedSongIndex]);
    }
    if (key == 'e' || key == 'E') {
      startEditor(songList[selectedSongIndex]);
    }
    if (keyCode == BACKSPACE) {
      iniciarTransicao(TELAINICIAL);//estado = TELAINICIAL;
    }
  }
  if (keyCode == BACKSPACE) {
    if (estado == RESULTADO || estado == GAMEOVER) {
      winning = false;
      gameOver = false;
      running = false;
      estado = MENU;
      drawMenu();
    }
  }
  if (key == ESC) { // voltar para menu
    key = 0; // evita fechar sketch
    stopAll();
  }
  if (key == 'r' || key == 'R') {
    if (estado == GAMEOVER) {
      estado = JOGO;
      gameOver = false;
      startGame(songList[selectedSongIndex], songListName[selectedSongIndex]);
    }
    
  }
  if (key == ' ') { // pausar
    //togglePause();
  }
  if (key == 'b' || key == 'B') { // cycle snapping
    if (snapping == 4) snapping = 8;
    else if (snapping == 8) snapping = 16;
    else snapping = 4;
  }
  if (editing) {
    handleEditorKeyPressed(key);
  }
  // Detecção de Hit In-Game para notas normais
  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) {
      boolean hit = tryHit(i);
      if (!hit) { // Nada para acertar, minima penalidade
        combo = 0;
        life -= 5;
        //effects.add(new HitEffect(mouseX, hitLineY, "miss"));
      }
      if (hit) {
      }
    }
  }
}

void keyReleased() {
  if (editing) {
    return;
  }
  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) {
      // release: check hold notes being held and finish
      for (Note n : notes) {
        if (n.lane == i && n.isHolding && !n.ended && music != null) {
          float now = music.position();
          if (now >= n.endTime - 0.05) { // released around end
            n.ended = true;
            // use hitTime (in place of non-existant startTime)
            int gained = (int)(100 * (n.endTime - n.hitTime)); // pontos por duração do hold
            score += gained;
            effects.add(new HitEffect(n.x, hitLineY, "holdend"));
            combo++;
            maxCombo = max(maxCombo, combo);
          } else {
            // early release -> cut hold
            n.ended = true;
            combo = 0;
            life -= 5;
            //effects.add(new HitEffect(n.x, hitLineY, "miss"));
          }
        }
      }
    }
  }
}

// Começando o jogo
void startGame(String song, String songName) {
  running = true;
  editing = false;
  paused = false;
  currentSongName = songName;
  score = 0; combo = 0; maxCombo = 0; life = 100;
  notes.clear();
  chart.clear();
  loadSongAndChart(song);
  spawnNotesFromChart();
  if (music != null) music.play();
}

void drawCountdown() {
  image(backgroundImage, 450, 350, 900, 700);
  //background(10, 10, 20);

  float now = millis() / 1000.0;
  float elapsed = now - countdownStartTime;

  int show = 3 - int(elapsed);

  textAlign(CENTER, CENTER);
  textSize(120);
  fill(255);

  if (show > 0) {
    fill(255, 100, 150);
    text(show, width/2, height/2);
  } 
  else if (show == 0) {
    fill(255, 100, 150);
    text("START!", width/2, height/2);
  } 
  else {
    isCountdown = false;
    estado = JOGO;
    startGame(songList[selectedSongIndex], songListName[selectedSongIndex]);         // começa só agora
    songStartTime = millis()/1000.0;
  }
}


// Iniciando o Editor
void startEditor(String songName) {
  if (menuMusicPlaying) {
    menuMusic.stop();
    menuMusicPlaying = false;
  }

  editing = true;
  running = false;
  paused = false;
  currentSongName = songName;
  notes.clear();
  chart.clear();
  loadSongAndChart(songName);
  if (music != null) music.play();
}

// Função para pausar
void togglePause() {
  paused = !paused;
  if (music != null) {
    if (paused) music.pause();
    else music.play();
  }
}

// Fução para parar tudo
void stopAll() {
  if (music != null) music.stop();
  running = false;
  editing = false;
  paused = false;
  notes.clear();
  chart.clear();
}

// Carregar a Musica e o Chart
void loadSongAndChart(String songName) {
  try {
    if (music != null) music.stop();
    music = new SoundFile(this, "musics/" + songName + ".mp3");
  } catch (Exception e) {
    println("Não conseguiu carregar música: data/musics/" + songName + ".mp3");
    music = null;
  }
  chart.load("data/charts/" + songName + ".txt"); // se não existir, Chart trata
}

// Spannar notas
void spawnNotesFromChart() {
  notes.clear();
  float now = 0;
  if (music != null) now = music.position();
  for (ChartEntry e : chart.entries) {
    float hitT = e.time;
    float startYpos = spawnY;
    float laneX = laneToX(e.lane);
    Note n = new Note(e.lane, laneX, hitT, noteSpeed, travelTime, spawnY, e.endTime);
    notes.add(n);
  }
  notes.sort((a,b) -> Float.compare(a.hitTime, b.hitTime));
}

void updateGame() {
  
  // GAME OVER
  if(life <= 0) {
     life = 0;
     running = false;
     music.stop();
     gameOver = true;
     estado = GAMEOVER;
  }
  // Terminou a música
  if (!music.isPlaying() && estado == JOGO) {
    running = false;
    music.stop();
    winning = true;
    estado = RESULTADO;
  }
  
  float t = music != null ? music.position() : millis()/1000.0;

  for (int i = notes.size()-1; i >= 0; i--) {
    Note n = notes.get(i);
    if (!n.hit && t - n.hitTime > 0.6) { // missed
      if (!n.isHold) {
        n.hit = true;
        combo = 0;
        life -= 5;
        //effects.add(new HitEffect(n.x, hitLineY, "miss"));
      } else {
        // missing a hold start or failing hold
        n.hit = true;
        combo = 0;
        life -= 8;
        //effects.add(new HitEffect(n.x, hitLineY, "miss"));
      }
    }
    n.update(t);
  }
}

void drawGame() {
  image(backgroundImage, 450, 350, 900, 700);
  drawLanes();
  if(!gameOver && !winning) {
    drawHitLine();
    drawGoodMinLine();
    drawGoodMaxLine();
    
    // Desenha notas
    for (Note n : notes) {
      n.draw(music != null ? music.position() : millis()/1000.0);
    }
    
    drawHUD();
  }
}

void drawGoodMaxLine() {
  // Tempo -> pixels
  float deltaPx = (hitWindowGoodMs / 1000.0) * noteSpeed;
  float goodMaxY = hitLineY - deltaPx;
  stroke(255, 200, 0);  // amarelo
  strokeWeight(2);
  line(0, goodMaxY, width, goodMaxY);
  noStroke();
}

void drawLanes() {
  // === FUNDO ===
  //imageMode(CORNER);
  //drawFullScreenImage(gameplayBG);  // usa aquela função de scale sem distorção

  float laneW = width / float(columns);

  // === LANES TRANSLÚCIDAS ===
  noStroke();
  for (int i = 0; i < columns; i++) {
    if (i % 2 == 0) fill(0, 0, 0, 170);  // preto transparente
    else fill(0, 0, 0, 150);              // variação leve
    rect(i * laneW, 0, laneW, height);
  }
}

void drawHitLine() {
  // === LABEL DAS TECLAS ===
  float laneW = width / float(columns);
  fill(220);
  textSize(40);
  textAlign(CENTER, CENTER);
  for (int i = 0; i < columns; i++) {
    text((char)keys[i], i * laneW + laneW/2, hitLineY + 40);
  }
  
  stroke(255, 0, 0);
  strokeWeight(3);
  line(0, hitLineY, width, hitLineY);
  noStroke();
}

void drawGoodMinLine() {
  float goodMinY = hitLineY + hitWindowGoodMs * (noteSpeed / 1000.0); 
  stroke(255, 200, 0);
  strokeWeight(2);
  line(0, goodMinY, width, goodMinY);
  noStroke();
}

void drawHUD() {
  fill(255);
  textSize(14);
  text("Song  " + currentSongName, 110, 20);
  text("Score  " + score, 110, 40);
  text("Combo  " + combo, 110, 60);
  text("MaxCombo  " + maxCombo, 110, 80);
  text("Life  " + life, 110, 100);
  // score bar
  fill(80);
  rect(10, 120, 200, 12);
  fill(0, 200, 0);
  rect(10, 120, map(life, 0, 100, 0, 200), 12);
}

boolean tryHit(int lane) {
  float now = music != null ? music.position() : millis()/1000.0;
  Note best = null;
  float bestDiff = 999;
  for (Note n : notes) {
    if (n.lane != lane) continue;
    if (n.hit) continue;
    float y = n.currentY(now);
    // só permitir notas que já estejam visíveis na tela
    if (y < -40 || y > height + 40) continue;
    
    float diff = abs(now - n.hitTime);
    if (diff < bestDiff) {
      bestDiff = diff;
      best = n;
    }
  }
  if (best == null) return false;
  if (best == null) {
    combo = 0;
    life -= 5;   // penalidade leve por apertar vazio
    //effects.add(new HitEffect(laneToX(lane), hitLineY, "miss"));
    return false;
  }

  int diffMs = (int)(bestDiff * 1000);
  if (diffMs <= hitWindowPerfectMs) {
    // perfect
    best.hit = true;
    score += 1000 + combo*5;
    combo++;
    maxCombo = max(maxCombo, combo);
    lifeStreak++;
    if (lifeStreak >= hitsToRecover) {
      life = min(100, life + 1);
      lifeStreak = 0;
    }
    if (hitSoundPerfect != null); //hitSoundPerfect.play();
    effects.add(new HitEffect(best.x, hitLineY, "perfect"));
    return true;
  } else if (diffMs <= hitWindowGoodMs) {
    // good
    best.hit = true;
    score += 500 + combo*2;
    combo++;
    maxCombo = max(maxCombo, combo);
    lifeStreak++;
    if (lifeStreak >= hitsToRecover) {
      life = min(100, life + 1);
      lifeStreak = 0;
    }
    if (hitSoundGood != null); //hitSoundGood.play();
    effects.add(new HitEffect(best.x, hitLineY, "good"));
    return true;
  } else {
    // too late/early -> miss
    best.hit = true;
    combo = 0;
    lifeStreak = 0;
    life -= 5;
    if (hitSoundMiss != null); //hitSoundMiss.play();
    //effects.add(new HitEffect(best.x, hitLineY, "miss"));
    return false;
  }
}

void updateEditor() {}

void drawEditor() {
  drawLanes();
  drawHitLine();

  float t = music != null ? music.position() : millis()/1000.0;
  float top = 40;
  float h = 120;
  fill(24);
  rect(0, 0, width, top + h);
  // grid lines per snapping
  float bpm = 120; // optional, but chart uses absolute seconds
  float measureSec = 60.0 / bpm;
  // draw grid based on snapping: we convert timeline to seconds per snap
  float snapSec = 60.0 / bpm / (snapping/4.0);
  // draw vertical markers across top area
  stroke(60);
  for (float s = t - 2.0; s < t + 10.0; s += snapSec) {
    float x = map(s, t - 2.0, t + 10.0, 0, width);
    line(x, top, x, top + h);
  }
  noStroke();

  for (ChartEntry e : chart.entries) {
    float x = map(e.time, t - 2.0, t + 10.0, 0, width);
    if (x < 0 || x > width) continue;
    float y = top + 20 + e.lane * 18;
    fill(200, 100, 200);
    rect(x-4, y, 8, 12);
    if (e.isHold) {
      float x2 = map(e.endTime, t - 2.0, t + 10.0, 0, width);
      rect(x, y+6, max(4, x2-x), 6);
    }
  }
  fill(255);
  text("EDITOR - Press A S D F G to add notes. P = Save Chart. Esc = Menu", width/2, 14); //B = Snapping (1/4,1/8,1/16). 
  text("Snapping: 1/" + (snapping/4) + "    Current Time: " + nf(music!=null?music.position():0,1,3), width/2, top + h + 10);
}

// Editor key presses
void handleEditorKeyPressed(char k) {
  if (k == 'p' || k == 'P') {
    chart.save("charts/" + currentSongName + ".txt");
    println("Chart salvo: charts/" + currentSongName + ".txt");
  }
  if (k == ' ') togglePause();

  // add note at current time with snapping
  float now = music != null ? music.position() : millis()/1000.0;
  float snapped = snapTime(now);
  for (int i = 0; i < keys.length; i++) {
    if (k == keys[i]) {
      // check if hold: if SHIFT pressed, create hold of length 1s default (you can adjust)
      if (keyEvent != null && keyEvent.isShiftDown()) {
        chart.addHold(snapped, i, snapped + 1.0); // hold 1s default
        println("Hold criado lane " + i + " start " + snapped + " end " + (snapped+1.0));
      } else {
        chart.add(snapped, i);
        println("Nota criada lane " + i + " time " + snapped);
      }
    }
  }
}

float snapTime(float t) {
  float bpm = 120.0; // default
  float beatSec = 60.0 / bpm;
  float division = snapping / 4.0; // snapping=16 -> division=4 -> 1/16
  float snapSec = beatSec / division;
  float s = round(t / snapSec) * snapSec;
  return s;
}

float laneToX(int lane) {
  float laneW = width / float(columns);
  return lane * laneW + laneW/2;
}
