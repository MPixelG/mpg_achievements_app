// a collection of different Easing functions. can be used for smooth movements for a camera or other stuff
enum AnimationStyle{
  easeIn, easeOut, linear, easeInOut
}

//the time has to be between 0 and 1, where 0 is the start of the animation and 1 is the end.
double linear(double time, {double startVal = 0, double endVal = 1}) {
  return startVal + (endVal - startVal) * time;
}

double easeIn(double time, {double startVal = 0, double endVal = 1}) {
  return startVal + (endVal - startVal) * (time * time);
}

double easeOut(double time, {double startVal = 0, double endVal = 1}) {
  return startVal + (endVal - startVal) * (1 - (1 - time) * (1 - time));
}

double easeInOut(double time, {double startVal = 0, double endVal = 1}) {
return time < 0.5
? startVal + (endVal - startVal) * (2 * time * time)
    : startVal + (endVal - startVal) * ((-2 * time * time) + (4 * time) - 1);
}