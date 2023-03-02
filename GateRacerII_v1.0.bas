  rem +-----------------------------------------------------------------------------------------+
  rem |                                                                                         |
  rem |                    									|                            
  rem |  Gate Racer II(i) - Save Key Enabled, assigned $0640 - $067F				|
  rem |  Steve Engelhardt 3/18/2013								|
  rem |												|
  rem |  4K project, batariBasic 1.1d	                  					|
  rem |                                                                                         |
  rem |  This game requires custom include files to compile it.					|
  rem |                                                                                         |
  rem |  They are available for download at the following links:				|
  rem |                                                                                         |
  rem |       http://www.atariage.com/forums/topic/						|
  rem |        208953-my-2k-game-experiment-gate-racer/page__st__25				|
  rem |                                                                                         |
  rem |   * Timer.inc										|
  rem |   * score_graphics_timer.asm								|
  rem |   * std_kernel.asm									|
  rem |   * pf_drawing.asm									|
  rem |   * pf_scrolling.asm									|
  rem |   * std_overscan.asm									|
  rem |                                                                                         |
  rem |       http://www.atariage.com/forums/topic/                                             |
  rem |       176797-bb-atarivox-support-part-1-the-atarivox-eeprom/page__hl__%20avoxeeprom     |
  rem |                                                                                         |
  rem |   * bbavox-eeprom-static.asm                                                            |
  rem |   * i2c.inc                                                                             |
  rem |                                                                                         |
  rem +-----------------------------------------------------------------------------------------+
  rem
  rem Revision 'i' Fixes savekey initialization issue
  rem              changes behavior of hitting oil slick with normal velocity
  rem              oil slick now resets to top after a crash
  rem              hitting the oil slick now produces a skidding sound
  rem              revamped the menu screen
  rem              Adds permanent savekey location for real hardware
  rem              Hold joystick up and press the game select switch to clear out the high score
  rem
  rem Note: The high score does not save until you press the fire button after a crash.
  rem
  rem Game Options:
  rem  Velocity control vs. normal control
  rem  oil slick on or off
  rem  size of car big or small
  rem  powerups on or off
  rem

  include fixed_point_math.asm
  include bbavox-eeprom-static.asm
  includesfile timer.inc
  set smartbranching on
  set romsize 4k

  const one_tenth = 6
  const leftborder = 15
  const rightborder = 138
  const AVoxSafetyOff=1

  dim xmove = a.b
  dim direction = c
  dim velocityx = d.d
  dim velocityy = e.e
  dim scroll = f.f
  dim counter = g
  dim crash = h
  dim crashflag = i
  dim powerflag = j
  dim option_screen = k
  dim extra = l
  dim oilrand = m
  dim option = n
  dim counter2 = o
  dim minutes=score
  dim seconds=score+1
  dim tenths=score+2
  dim frames=s
  dim state=t
  dim savescr1=u
  dim savescr2=v
  dim savescr3=w
  dim animate=x

  rem The following dim's allow us to access the bytes that make up
  rem the bB score as regular variables...
  dim sc1=score
  dim sc2=score+1
  dim sc3=score+2

Restart
  rem
  rem I set the titlescreen sprite here instead of in the 'Begin' loop so it doesn't flash
  rem on the screen every time you restart the game.
  rem
  player1:
  %01111110
  %00100100
  %00100100
  %00100100
  %01111110
  %00000000
  %00000000
  %11100101
  %10000110
  %10000111
  %11000101
  %10000111
  %10000000
  %11100111
  %00000100
  %01000110
  %01000100
  %01000111
  %01000000
  %01000111
  %11100100
  %00000100
  %10100100
  %10100111
  %10100000
  %11100101
  %10100101
  %10100111
  %11100101
  %00000111
  %11100000
  %10100101
  %10100110
  %10100111
  %10000101
  %11100111
end

  rem Set default options
  rem
  option{1}=1: rem Velocity on/off (on)
  option{2}=1: rem Oil Slick on/off (on)
  option{3}=1: rem Car Size big/normal (normal)
  option{4}=1: rem PowerUps on/off (on)

  rem Read High Score from SaveKey
  rem
  sc1=AVoxReadByte($06,$40)
  sc2=AVoxReadByte($06,$50)
  sc3=AVoxReadByte($06,$60)

  rem Initialize Atarivox/SaveKey eeprom if it contains $FFFFFF
  rem  Or, if you press joy0up and the game select key from the titlescreen,
  rem  it will clear out the high score.
  rem
  if sc1<>$ff && sc2<>$ff && sc3<>$ff then goto skipclear
clearit
  pfclear
  sc1=0:sc2=0:sc3=0:drawscreen
  temp2=AVoxWriteByte($06,$40,0):drawscreen
  temp2=AVoxWriteByte($06,$50,0):drawscreen
  temp2=AVoxWriteByte($06,$60,0):drawscreen
skipclear

  rem Define initial playfield. Put it in a sub since I use it more than once.
  rem
  gosub playdefine

Begin
  rem ----------------------------Title screen Loop Start--------------------------------
  rem |                                                                                 |

  if joy0up && switchselect then goto clearit

  pfscroll down

  rem This sets the non-scrolling sides of the road.
  rem
  PF0=200

  rem The ball creates the blue background behind the word 'gate'.
  rem  I thought it looked better than just the plain white sprite.
  rem  
  ballheight=30
  ballx=73:bally=55

  rem This sets the missile to 8 pixels wide and two wide copies on the screen.
  CTRLPF=$31

  rem set color and location of titlescreen sprite
  rem
  COLUP1=8
  player1x=72:player1y=63

  rem set titlescreen sprite to double width
  rem
  NUSIZ1=$05
  NUSIZ0=$30

  scorecolor = 8

  rem Playfield Color
  rem
  COLUPF = 66

  drawscreen

  rem Hit fire button to exit the loop and start the game.
  rem   z=77 sets initial oil slick x location. I want it to be in the middle of the
  rem   screen every time you restart.
  rem
  if joy0fire then goto options
  if !joy0fire then z=77:goto Begin

  rem |                                                                                 |
  rem ----------------------------Title screen Loop End----------------------------------


Init
  rem ------------------------Initialize Game/Restart Game-------------------------------
  rem |                                                                                 |

  rem reset oil slick to top of screen
  rem
  z=77 : y=0

  missile1x=0:missile1y=0

  rem oil slick sprite
  rem
  player1:
  %01010011
  %11001110
  %01111100
  %00110111
  %11111110
  %00110111
  %01100100
  %00111110
  %11111110
  %01010111
end

  rem assign player sprite (The Car)
  rem
  player0:
  %01111110
  %01000010
  %00111100
  %10100101
  %11100111
  %10111101
  %00111100
  %10011001
  %11111111
  %10011001
end

  rem Initialize variables
  rem

  xmove = 77.0
  velocityx = 0.0
  score = 0
  counter = 1
  crash = 0
  crashflag = 0

  rem Need to reset missile0 location or it messes up the powerup when you restart.
  rem
  missile0x=0:missile0y=0

  rem clear entire playfield. The game resets to 'Init' above when you die, need to clear
  rem  the playfield every time here.
  rem
  pfclear %00000000

  rem Playfield Color
  rem
  COLUPF = $86

  rem Define initial playfield. Put it in a sub since I use it more than once.
  rem
  gosub playdefine

  rem |                                                                                 |
  rem ----------------------Initialize Game/Restart Game End-----------------------------

Main
  rem ------------------------------Main Loop Start--------------------------------------
  rem |                                                                                 |

  x=x+1

  if x>4 then x=0
  
  if x=2 then player0:
  %01111110
  %01000010
  %00111100
  %10100101
  %11100111
  %10111101
  %00111100
  %10011001
  %11111111
  %10011001
end

  if x=4 then player0:
  %01111110
  %01000010
  %00111100
  %10100101
  %01100110
  %10111101
  %00111100
  %10011001
  %01111110
  %10011001
end

  if switchreset then reboot

  rem set Y location of player sprite (car)
  rem
  player0y = 85

  rem ---------------------
  rem Powerup Code
  rem
  rem increase height and width of missile
  rem
  rem 20 for normal car, 25 for double width car
  rem
  if !option{3} then NUSIZ0=$25:goto skipcar
  NUSIZ0=$20
skipcar
  missile0height=5
  rem
  rem this line allows for no more powerups to appear when you're already invincible
  rem
  if j=1 then missile0y=0:missile0x=0:goto skippower
  rem
  rem This randomizes how often the powerup appears.
  rem if the random number is greater than 35, no powerup will appear.
  rem
  if z>30 then skippower
  rem
  rem Show the powerup
  rem
  if !option{4} then skippower
  missile0x=90+q:missile0y=counter+27
skippower
  rem ---------------------

  rem
  rem Counter2 is incremented once per scrolling gate. After three, turn invicibility off.
  rem
  if collision(player0,missile0) then counter2=0:j=1
  if counter2>2 then j=0:counter2=0

  rem Remove the pixels for the gate opening
  rem
  pfhline q 0 r off  

  rem Turn off crash sound
  rem
  AUDV1=0

  rem Draw non-scrolling Road borders
  rem
  PF0=200

  rem Oil slick----------- 
  rem
  rem set oil slick color to dark grey
  rem
  if !option{2} then player1:
  %00000000
end
  if !option{2} then COLUP1=0:goto skipoil
  COLUP1=2
  rem
  rem make oil slick wider (double size)
  rem
  NUSIZ1=$05 
  rem
  rem set X/Y position for the Oil Slick
  rem
  player1x=z:player1y=y
skipoil
  rem ---------------------

  rem  This makes an 'engine rumble' sound. 
  rem
  AUDF0=18:AUDC0=14:AUDV0=9
  rem
  rem  This makes a sound when you hit the oil slick
  rem
  if collision(player1,player0) then AUDF1=state+8:AUDC1=12:AUDV1=6

  rem next line slows the oil slick down as it moves down the screen
  rem
  state=state+1
  if state>2 then y=y+1: state=0

  rem This section controls the clock timer
  rem  Nothing can be removed from this section
  rem
  tenths=tenths|$A0
  minutes=minutes|$0B
  drawscreen
  frames=frames+1:if frames<>one_tenth then skip_tenths
  frames=0
  tenths=tenths&$0F
  minutes=minutes&$F0
  score=score+1
  if tenths=$10 then score=score+90
  if seconds=$60 then score=score+94000
skip_tenths

  rem Turn on pixel blocks that scroll down the sides of the road
  rem
  var0=var0|%10000000
  var3=var3|%10000000

  rem this of course sets the screen to scroll down
  rem
  pfscroll down 
 
  rem set the color of the score
  rem
  scorecolor = 8

  rem counter for changing the barriers
  rem
  counter=counter+1

  rem I timed the counter to expire just as the barrier hits the bottom of the screen
  rem After it expires, jump to the subroutine that draws a new one.
  rem counter2 is incremented to 3 then reset. It controls how long you're invincible
  rem after you pick up a powerup.
  rem
  if counter>87 then counter=0:counter2=counter2+1:goto change_barrier
barrier_return

  rem Setting the Right difficulty switch to A will skip the X/Y velocity
  rem  You'll stop moving as soon as you stop pressing in one direction.
  rem
  if !option{1} then goto altcontrol

  rem player velocity code
  rem
  if joy0right && direction then velocityx=velocityx+0.100
  if joy0left && !direction then velocityx=velocityx-0.100
  xmove = xmove + velocityx
  player0x = xmove
  if xmove<=leftborder then velocityx=-velocityx : direction=1
  if xmove>=rightborder then velocityx=-velocityx : direction=0

  rem player movement code
  rem
  if joy0right then direction = 1
  if joy0left then direction = 0
  if direction then velocityx=velocityx-0.0040 else velocityx=velocityx+0.0050

altcontrol
  rem 'No velocity' controls 
  rem
  if joy0left then player0x=player0x-1
  if joy0right then player0x=player0x+1
skip

  rem Powerup is turned on, skip collisions as long as j flag is active.
  rem
  if j=1 then COLUP0=counter:goto skipexplode
  rem

  rem if the player sprite (car) touches the playfield... Game over, man.
  rem
  if collision(player0,playfield) then goto explode
  if !collision(player1,player0) then skipexplode
  rem
  rem skid the car if you hit the oil slick
  rem
  oilrand=(rand&3)+2
  if option{1} then player0x=player0x+oilrand:goto skipexplode
  if state=1 then player0x=player0x+oilrand
  if state=2 then player0x=player0x-oilrand
skipexplode

  rem That's it, loop back.
  rem
  goto Main

  rem |                                                                               |
  rem ------------------------------Main Loop End--------------------------------------

explode

  rem ---------------------------Car Crash Loop Start----------------------------------
  rem |                                                                               |
   

  rem This will remove the powerup from the screen if you crash while it's still on
  rem the screen.  It will stay in place and not move when the game starts back up
  rem if you don't remove it here.
  rem
  missile0y=0:missile0x=0

  if !option{3} then NUSIZ0=$25 else NUSIZ0=$20

  rem Change score color to red when you crash
  rem
  scorecolor = $44

  rem Crash Counter
  rem  Used to turn off crash sound & flash colors
  rem
  crash=crash+1
  if crash>48 then crash=1:crashflag=1

  rem Set playfield road boundaries
  rem
  PF0=200

  rem This is to make the oil slick appear correctly on the crash screen.
  rem  Without it, it changes size and color.
  rem  Not needed but looks much better with it.
  rem
  NUSIZ1=$05: COLUP1=2

  rem Change car color when you die to red
  rem
  COLUP0=66

  rem This creates the random bit pattern on the car sprite when you crash.
  rem
  player0pointerhi=rand
  
  rem Turns off sounds after counter expires.
  rem 
  if !crashflag then AUDF1=28:AUDC1=8:AUDV1=12 else AUDV0=0:AUDV1=0

  rem This looks like duplicate code from the main loop, but it's required.
  rem If I don't add the tenths and minutes in this loop they won't display correctly
  rem  when the game ends. 
  rem
  tenths=tenths|$A0
  minutes=minutes|$0B

  if switchreset then reboot

  rem Reset the Game when you hit fire.
  rem
  if joy0fire then player0x=77:goto CheckScore

  drawscreen

  rem loop back
  rem
  goto explode

  rem |                                                                               |
  rem ---------------------------Car Crash Loop End------------------------------------

change_barrier

  rem -----------------------Gate Change Subroutine Start------------------------------
  rem |                                                                               |

  rem clear playfield variables to erase border
  rem
  var44=%10000000:var47=%10000000:var45=0:var46=0

  rem random number for placement of oil slick
  rem
  if y>90 then z = (rand&95)+20

  rem This code randomly changes the barrier openings.  
  rem
  rem First I draw a solid pfhline, then I cut out the opening with two random numbers.
  rem  Q is the left X position of the opening
  rem  R is the right X position of the opening

  rem Calculate X position of the Left side of the opening
  rem
  q = (rand&31)

  rem
  rem If the Random number is 15 or higher, I subtract the width
  rem   to ensure the size of the opening on the right side is big enough.
  rem
  if q>15 then q=q-6
 
  rem Calculate X position of the Right side of the opening
  rem
  r = q+6

  rem Draw the solid horizontal line
  rem
  pfhline 0 0 31 on 

  goto barrier_return

  rem |                                                                               |
  rem -----------------------Gate Change Subroutine End--------------------------------

CheckScore

  rem ---------------------Check and Save High Score Start-----------------------------
  rem |                                                                               |

  PF0=0

  rem pfclear

  rem clear oil slick from screen before restarting
  player1:
  %00000000
end
  rem COLUP1=0

  rem Load existing values from the Save Key
  rem  The eeprom needs about 5000 cycles after each command before it becomes responsive again, so a drawscreen is required each time.
  rem  The same applies for AvoxWriteByte
  rem
  savescr1=AVoxReadByte($06,$40) 
  drawscreen
  savescr2=AVoxReadByte($06,$50)
  drawscreen
  savescr3=AVoxReadByte($06,$60) 
  drawscreen

CompareScores

  rem
  rem Compare Minutes
  rem
  rem 1. If the new minute number(sc1) is higher than savescr1 we will always write all three values (sc1, sc2, sc3) then skip to end
  rem
  if savescr1 < sc1 then temp2=AVoxWriteByte($06,$40,sc1):drawscreen: temp2=AVoxWriteByte($06,$50,sc2):drawscreen: temp2=AVoxWriteByte($06,$60,sc3):drawscreen: goto skiptoend
  rem
  rem 2.  If the new minute number(sc1) is equal  to   savescr1 we will skip to processing seconds
  rem
  if savescr1 = sc1 then skiptoseconds
  rem
  rem 3.  If the new minute number(sc1) is lower  than savescr1 we will do nothing and skip to end
  rem
  if savescr1 > sc1 then skiptoend

skiptoseconds

  rem
  rem Compare Seconds
  rem
  rem 1.  If the new seconds number(sc2) is higher than savescr2 we will always write to sc2 and sc3 then skip to end
  rem
  if savescr2 < sc2 then temp2=AVoxWriteByte($06,$50,sc2):drawscreen: temp2=AVoxWriteByte($06,$60,sc3):drawscreen: goto skiptoend
  rem
  rem 2.  If the new seconds number(sc2) is equal  to   savescr2 we will skip to processing tenths of seconds
  rem
  if savescr2 = sc2 then skiptotenths
  rem
  rem 3.  If the new seconds number(sc2) is lower  than savescr2 we will do nothing and skip to end
  rem
  if savescr2 > sc2 then skiptoend

skiptotenths

  rem
  rem Compare Tenths
  rem
  rem 1.  If the new seconds number(sc3) is higher than savescr3 we will always write to sc3
  rem
  if savescr3 < sc3 then temp2=AVoxWriteByte($06,$60,sc3):drawscreen: goto skiptoend
  rem
  rem 2.  If the new seconds number(sc3) is equal  to   savescr3 we will do nothing and skip to end
  rem
  rem if savescr3 = sc3 then skiptoend
  rem
  rem 3.  If the new seconds number(sc3) is lower  than savescr3 we will do nothing and skip to end
  rem
  rem if savescr3 > sc3 then skiptoend

skiptoend

  goto Init

  rem |                                                                               |
  rem ----------------------Check and Save High Score End------------------------------

options

  rem ---------------------------Options Loop Start------------------------------------
  rem |                                                                               |

  rem Options Screen
  rem
  rem  Velocity control vs. normal control
  rem  oil slick on or off
  rem  size of car
  rem  powerups on or off
 
  x=7
  z=0

  COLUPF=$86

  option_screen{1}=1
  option_screen{2}=0
  option_screen{3}=0
  option_screen{4}=0

  player1x=16

options2

 rem missile1x=134:missile1y=70
 rem missile1height=42
 rem ballx=142:bally=69
 rem ballheight=42

 player1:
 %00001000
 %00001000
 %00000100
 %00000100
 %00000010
 %00000010
 %11111111
 %11111111
 %00000010
 %00000010
 %00000100
 %00000100
 %00001000
 %00001000
end
 
  NUSIZ1=$37
  NUSIZ0=$05

  player1y=21

  COLUP1=$86
  COLUP0=10

  if joy0right then x=x+1
  if joy0left then x=x-1

  player0x=132:player0y=65

  if joy0fire && z=0 then z=1
  if !joy0fire && z=1 then z=2
  if joy0fire && z=2 then z=77:player0x=77:goto Init

  if x<0 then x=31
  if x>31 then x=0

  if x=7 then gosub opt1_velocity
  if x=14 then gosub opt2_oilslick
  if x=21 then gosub opt3_carsize
  if x=31 then gosub opt4_powerups

  rem Velocity ON/OFF
  if option_screen{1} && option{1} then gosub opt_on
  if option_screen{1} && !option{1} then gosub opt_off
  if joy0up && option_screen{1} && option{1} then option{1}=0
  if joy0down && option_screen{1} && !option{1} then option{1}=1

  rem Oil Slick ON/OFF
  if option_screen{2} && option{2} then gosub opt_on
  if option_screen{2} && !option{2} then gosub opt_off
  if joy0up && option_screen{2} && option{2} then option{2}=0
  if joy0down && option_screen{2} && !option{2} then option{2}=1

  rem Car Size
  if option_screen{3} && option{3} then gosub opt_small
  if option_screen{3} && !option{3} then gosub opt_big
  if option_screen{3} && option{3} then gosub opt_small
  if option_screen{3} && !option{3} then gosub opt_big
  if joy0up && option_screen{3} && option{3} then option{3}=0
  if joy0down && option_screen{3} && !option{3} then option{3}=1

  rem Powerup ON/OFF
  if option_screen{4} && option{4} then gosub opt_on
  if option_screen{4} && !option{4} then gosub opt_off
  if joy0up && option_screen{4} && option{4} then option{4}=0
  if joy0down && option_screen{4} && !option{4} then option{4}=1

  drawscreen

  goto options2

opt1_velocity
 player1x=16
  playfield:
  ................................
  ................................
  ................................
  ................................
  X.X.XX.X..XXX.XX.X.XXX.X.X......
  X.X.X..X..X.X.X..X..X..X.X......
  X.X.XX.X..X.X.X..X..X..XXX......
  X.X.X..X..X.X.X..X..X...X.......
  .X..XX.XX.XXX.XX.X..X...X.......
  ................................
  ................................
  ................................
end
  option_screen{1}=1
  option_screen{2}=0
  option_screen{3}=0
  option_screen{4}=0
  option_screen{5}=0
  return

opt2_oilslick
  player1x=41
  playfield:
  ................................
  ................................
  ................................
  ................................
  XXX.X.X...XXX.X...X.XX.X..X.....
  X.X.X.X...X...X...X.X..X.X......
  X.X.X.X...XXX.X...X.X..XX.......
  X.X.X.X.....X.X...X.X..X.X......
  XXX.X.XX..XXX.XXX.X.XX.X..X.....
  ................................
  ................................
  ................................
end
  option_screen{1}=0
  option_screen{2}=1
  option_screen{3}=0
  option_screen{4}=0
  option_screen{5}=0
  return
 
opt3_carsize 
  player1x=66
  playfield:
  ................................
  ................................
  ................................
  ................................
  XXX.XXX.XXX..XXX.X.XXX.XXX......
  X...X.X.X.X..X...X...X.X........
  X...XXX.XXX..XXX.X..X..XX.......
  X...X.X.XX.....X.X.X...X........
  XXX.X.X.X.X..XXX.X.XXX.XXX......
  ................................
  ................................
  ................................
end
  option_screen{1}=0
  option_screen{2}=0
  option_screen{3}=1
  option_screen{4}=0
  return

opt4_powerups
  player1x=91
  playfield:
  ................................
  ................................
  ................................
  ................................
  XXX.XXX.X...X.XX.XXX.X.X.XXX....
  X.X.X.X.X...X.X..X.X.X.X.X.X....
  XXX.X.X.X.X.X.XX.XXX.X.X.XXX....
  X...X.X.XX.XX.X..XX..X.X.X......
  X...XXX.X...X.XX.X.X.XXX.X......
  ................................
  ................................
  ................................
end
  option_screen{1}=0
  option_screen{2}=0
  option_screen{3}=0
  option_screen{4}=1
  return


opt_off
 player0:
 %00010000
 %00111000
 %01010100
 %00010000
 %00010000
 %00000000
 %00000000
 %00000100
 %00000100
 %00000110
 %00000100
 %00000111
 %00000000
 %00010000
 %00010000
 %00011000
 %00010000
 %00011100
 %00000000
 %11100000
 %10100000
 %10100000
 %10100000
 %11100000
end
 return

opt_on
 player0:
 %11101001
 %10101001
 %10101011
 %10101101
 %11101001
 %00000000
 %00000000
 %00010000
 %00010000
 %01010100
 %00111000
 %00010000
end
  return

opt_small
 player0:
 %11111000
 %10000000
 %10000000
 %10000000
 %10000000
 %00000000
 %11111000
 %10000000
 %10000000
 %10000000
 %10000000
 %00000000
 %10001000
 %10001000
 %11111000
 %10001000
 %11111000
 %00000000
 %10001000
 %10001000
 %10001000
 %10101000
 %11011000
 %00000000
 %11111000
 %00001000
 %11111000
 %10000000
 %11111000
 %00000000
 %00000000
 %00100000
 %00100000
 %10101000
 %01110000
 %00100000
end
 return

opt_big
 player0:
 %00010000
 %00111000
 %01010100
 %00010000
 %00010000
 %00000000
 %00000000
 %00001111
 %00001001
 %00001011
 %00001000
 %00001111
 %00000000
 %00111000
 %00010000
 %00010000
 %00010000
 %00111000
 %00000000
 %11100000
 %10010000
 %11100000
 %10010000
 %11100000
end
  return

  rem |                                                                               |
  rem ---------------------------Options Loop End--------------------------------------

playdefine
  playfield:
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
  X..............................X
end
  return

