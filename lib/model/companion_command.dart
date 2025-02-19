// command 종류
enum Command {
  // down and up
  press,

  // down : 누름. up이 없으면 hold
  down,

  // up : 안 누름. down이 선행되지 않으면 무효
  up,
}