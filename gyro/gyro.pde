/*
https://developer.android.com/reference/android/hardware/Sensor#TYPE_GYROSCOPE
*/

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.view.KeyEvent;

import processing.sound.*;

SoundFile start_audio;
SoundFile neutral_audio;
SoundFile forward_audio;
SoundFile backward_audio;
SoundFile right_tilt_audio;
SoundFile left_tilt_audio;
SoundFile right_twist_audio;
SoundFile left_twist_audio;
SoundFile good_job_audio;
SoundFile flow_slowly_audio;

Context context;
SensorManager manager;
Sensor sensor;
GyroscopeListener listener;


float gx, gy, gz;

int zero_threshold = 15;
long start_time;
boolean isForward;
boolean isBackward;
String display = "";

enum State {
  NEUTRAL_1,
  FORWARD,
  NEUTRAL_2,
  BACKWARD,
  NEUTRAL_3,
  RIGHT_TILT,
  NEUTRAL_4,
  LEFT_TILT,
  NEUTRAL_5,
  RIGHT_TWIST,
  NEUTRAL_6,
  LEFT_TWIST,
  NEUTRAL_7
}

State prev_state;
long prev_state_millis;
State curr_state;
long curr_state_millis;

long action_started_millis;
boolean action_started;
boolean action_aborted;
boolean action_succeded;
boolean sound_played;

void reset_action_vars() {
    action_aborted = false;
    action_started = false;
    action_succeded = false;
    sound_played = false;
}

void setup() {
  start_audio = new SoundFile(this, "deep_breath.mp3");
  neutral_audio = new SoundFile(this, "come_back_to_neutral.mp3");
  forward_audio = new SoundFile(this, "chin_to_chest.mp3");
  backward_audio = new SoundFile(this, "chin_to_sky.mp3");
  right_tilt_audio = new SoundFile(this, "right_ear_to_right_shoulder.mp3");
  left_tilt_audio = new SoundFile(this, "left_ear_to_left_shoulder.mp3");
  right_twist_audio = new SoundFile(this, "chin_to_right shoulder.mp3");
  left_twist_audio = new SoundFile(this, "chin_to_left_shoulder.mp3");
  good_job_audio = new SoundFile(this, "good_job.mp3");
  flow_slowly_audio = new SoundFile(this, "flow_slowly.mp3");
  
  fullScreen();
  
  context = getActivity();
  manager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);
  sensor = manager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
  listener = new GyroscopeListener();
  manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME);
  
  textFont(createFont("SansSerif", 40 * displayDensity));

  curr_state = State.NEUTRAL_1;
  curr_state_millis = millis();
}

boolean isSteady(float value) {
  value = abs(value);    
  return value <= zero_threshold;
}

void keyPressed() {
  if (key == CODED && keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
    reset_action_vars();
    curr_state = State.NEUTRAL_1;
    start_audio.play();
    delay(3000);
    flow_slowly_audio.play();
    delay(3000);
  }
}

void process_state(float var_, int action_time, State next_state) {
  // here we look for movement along X for making sure we go forward
  if (var_ > zero_threshold && !action_started) {
      // we have started the action
      action_started = true;
      action_started_millis = millis();
  } else if (action_started) {
      // we need to see how long we have been in action for
      if ((millis() - action_started_millis) > action_time) {
          action_succeded = true;
          System.out.println("ACTION SUCCEDED!" + curr_state.toString());
          curr_state = next_state;
          reset_action_vars();
      }
      if (var_ < 0) {
          action_aborted = true;
          System.out.println("ACTION ABORTED!" + curr_state.toString());
          reset_action_vars();
      }
  }
}

void draw() {
  background(0);
  text("X: " + gx * 100 + "\nY: " + gy * 100 + "\nZ: " + gz * 100, 10, 10, width, height); 
  text(curr_state.toString(), 0, height/2);
  text("action_started:\n" + action_started, 0, height/3);

  float var_;
  int action_time;
  switch (curr_state) {
    case NEUTRAL_1:
        if (!sound_played && !forward_audio.isPlaying()) {
          forward_audio.play(); 
          sound_played=true;
        }
        // action here we are searching for is +Y for 1.5
        var_ = gy * 100 * 1; // multiply by -1 if we need to care about other side
        action_time = 2500;
        process_state(var_, action_time, State.FORWARD);
        break;
    case FORWARD:
        if (!sound_played && !neutral_audio.isPlaying() && !forward_audio.isPlaying()) {
          neutral_audio.play(); 
          sound_played=true;
        }
        // here we look to go backward for 1.5s
        // action here we are searching for is +Y for 1.5
        var_ = gy * 100 * -1; // multiply by -1 if we need to care about other side
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_2);
        break;
    case NEUTRAL_2:
        if (!sound_played && !backward_audio.isPlaying() && !neutral_audio.isPlaying()) {
          backward_audio.play(); 
          sound_played=true;
        }
        // here we look to go backward for 1.5s
        var_ = gy * 100 * -1; // multiply by -1 if we need to care about other side
        action_time = 2500;
        process_state(var_, action_time, State.BACKWARD);
        break;
    case BACKWARD:
        if (!sound_played && !neutral_audio.isPlaying() && !backward_audio.isPlaying()) {
          neutral_audio.play();
          sound_played=true;
        }
        var_ = gy * 100 * 1; // multiply by -1 if we need to care about other side
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_3);
        break;
    case NEUTRAL_3:
        if (!sound_played && !right_tilt_audio.isPlaying() && !neutral_audio.isPlaying()) {
          right_tilt_audio.play(); 
          sound_played=true;
        }
        var_ = gz * 100 * 1; // we expect z to go +ve
        action_time = 2500;
        process_state(var_, action_time, State.RIGHT_TILT);
        break;
    case RIGHT_TILT:
        if (!sound_played && !neutral_audio.isPlaying() && !right_tilt_audio.isPlaying()) {
          neutral_audio.play(); 
          sound_played=true;
        }
        var_ = gz * 100 * -1; // we expect z to go +ve
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_4);
        break;
    case NEUTRAL_4:
        if (!sound_played && !left_tilt_audio.isPlaying() && !neutral_audio.isPlaying()) {
          left_tilt_audio.play(); 
          sound_played=true;
        }
        var_ = gz * 100 * -1; // we expect z to go +ve
        action_time = 2500;
        process_state(var_, action_time, State.LEFT_TILT);
        break;
    case LEFT_TILT:
        if (!sound_played && !neutral_audio.isPlaying() && !left_tilt_audio.isPlaying()) {
          neutral_audio.play(); 
          sound_played=true;
        }
        var_ = gz * 100 * 1; // we expect z to go +ve
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_5);
        break;
    case NEUTRAL_5:
        if (!sound_played && !right_twist_audio.isPlaying() && !neutral_audio.isPlaying()) {
          right_twist_audio.play(); 
          sound_played=true;
        }
        var_ = gx * 100 * 1; // we expect y to go +ve
        action_time = 2500;
        process_state(var_, action_time, State.RIGHT_TWIST);
        break;
    case RIGHT_TWIST:
        if (!sound_played && !neutral_audio.isPlaying() && !right_twist_audio.isPlaying()) {
          neutral_audio.play(); 
          sound_played=true;
        }
        var_ = gx * 100 * -1; // we expect z to go +ve
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_6);
        break;
    case NEUTRAL_6:
        if (!sound_played && !left_twist_audio.isPlaying() && !neutral_audio.isPlaying()) {
          left_twist_audio.play(); 
          sound_played=true;
        }
        var_ = gx * 100 * -1; // we expect z to go +ve
        action_time = 2500;
        process_state(var_, action_time, State.LEFT_TWIST);
        break;
    case LEFT_TWIST:
        if (!sound_played && !neutral_audio.isPlaying() && !left_twist_audio.isPlaying()) {
          neutral_audio.play(); 
          sound_played=true;
        }
        var_ = gx * 100 * 1; // we expect z to go +ve
        action_time = 1700;
        process_state(var_, action_time, State.NEUTRAL_7);
        break;
    case NEUTRAL_7:
        System.out.println("DONE");
        text("GOOOOOOD DAY", 0, height*2/3);
        if (!sound_played && !good_job_audio.isPlaying() && !neutral_audio.isPlaying()) {
          good_job_audio.play();
          sound_played = true;
        }
        
        break;
  }
  delay(100);
}

class GyroscopeListener implements SensorEventListener {
  public void onSensorChanged(SensorEvent event) {
    gx = event.values[0];
    gy = event.values[1];
    gz = event.values[2];    
  }
  public void onAccuracyChanged(Sensor sensor, int accuracy) {
  }
}
