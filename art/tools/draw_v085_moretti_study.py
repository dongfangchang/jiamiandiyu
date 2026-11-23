"""Original, locally drawn illustration study. No network or external imagery.
One preview only; not installed as a runtime asset. Seeded for reproducibility.
Run with Pillow: python art/tools/draw_v085_moretti_study.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import math, random

R = random.Random(8501)
W,H,S=840,1180,1.5
im=Image.new('RGB',(1260,1770))
d=ImageDraw.Draw(im)
INK=(30,36,35); LIGHT=(198,180,136); GOLD=(174,145,91)

def xy(points): return [(round(x*S),round(y*S)) for x,y in points]
def poly(points,fill,outline=None,width=1):
 d.polygon(xy(points),fill=fill)
 if outline: line(points+[points[0]],outline,width)
def line(points,fill=INK,width=1):d.line(xy(points),fill=fill,width=max(1,round(width*S)),joint='curve')
def rect(box,fill,outline=None,width=1):
 d.rectangle(tuple(round(n*S) for n in box),fill=fill,outline=outline,width=max(1,round(width*S)))
def ellipse(box,fill,outline=None,width=1):
 d.ellipse(tuple(round(n*S) for n in box),fill=fill,outline=outline,width=max(1,round(width*S)))
def blend(a,b,t):return tuple(round(x+(y-x)*t) for x,y in zip(a,b))
def glow(x,y,rx,ry,color,alpha):
 global im,d
 layer=Image.new('RGBA',im.size)
 g=ImageDraw.Draw(layer)
 g.ellipse(tuple(round(n*S) for n in (x-rx,y-ry,x+rx,y+ry)),fill=(*color,alpha))
 layer=layer.filter(ImageFilter.GaussianBlur(rx*S*.40))
 im=Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB');d=ImageDraw.Draw(im)

def hatch_polygon(points,color,spacing=7,slope=-.5,opacity=80):
 global im,d
 mask=Image.new('L',im.size);md=ImageDraw.Draw(mask);md.polygon(xy(points),fill=opacity)
 strokes=Image.new('RGB',im.size);sd=ImageDraw.Draw(strokes)
 sm=Image.new('L',im.size);sdm=ImageDraw.Draw(sm)
 xs=[p[0] for p in points];ys=[p[1] for p in points]
 for y in range(int(min(ys)-W),int(max(ys)+W),spacing):
  pts=xy([(min(xs)-3,y),(max(xs)+3,y+(max(xs)-min(xs))*slope)])
  sd.line(pts,fill=color,width=1);sdm.line(pts,fill=255,width=1)
 mask=ImageChops.multiply(mask,sm)
 im.paste(strokes,(0,0),mask);d=ImageDraw.Draw(im)

# Rain-laden sky: ink washes with low contrast, no baked paper texture.
for y in range(H):
 t=min(y/880,1)
 c=blend((100,113,109),(48,60,58),t)
 d.rectangle((0,round(y*S),1260,round((y+1)*S)),fill=c)
for _ in range(22):
 x,y=R.randint(-100,900),R.randint(-80,390)
 glow(x,y,R.randint(90,220),R.randint(15,55),(126,135,125),R.randint(12,26))
# Distant row of houses: lowered contrast and softened silhouettes.
for x,y,w in [(-60,370,150),(50,335,145),(155,390,155),(265,410,110)]:
 poly([(x,y+45),(x+w,y+36),(x+w,780),(x,815)],(65,77,73))
 poly([(x-12,y+50),(x+w*.48,y-15),(x+w+9,y+40)],(52,65,62))
 rect((x+w*.70,y-44,x+w*.80,y+10),(61,73,69))
 for yy in range(y+90,730,87):
  for xx in range(x+20,x+w-10,42):
   rect((xx,yy,xx+18,yy+35),(48,61,58))
   line([(xx+8,yy),(xx+8,yy+35)],(81,89,80))
# Perspective lane with curving gutter.
poly([(0,766),(350,670),(840,764),(840,1180),(0,1180)],(58,69,66))
poly([(347,695),(562,758),(840,1180),(115,1180)],(66,77,72))
line([(344,695),(308,803),(248,931),(115,1180)],(110,116,100),3)
line([(354,698),(320,804),(261,935),(130,1180)],(32,44,42),5)
# Irregular stone paving converging on the door, not a screen-space grid.
y=718;row=0
while y<1200:
 depth=(y-695)/485
 height=9+depth*33
 x=-120+(row%2)*38
 while x<950:
  width=23+depth*104+R.uniform(-8,9)
  off=R.uniform(-2.5,2.5)
  pts=[(x+4,y+off),(x+width-6,y+off-2),(x+width+6,y+height-4),(x-9,y+height-2)]
  c=R.choice([(61,73,69),(69,79,72),(75,84,75),(54,68,65),(80,88,78)])
  poly(pts,c,(43,56,53),.7)
  if R.random()<.58:line([pts[0],pts[1]],(103,110,94),.7)
  x+=width
 y+=height;row+=1
# Main house: a narrow nineteenth-century masonry townhouse with deep side wall.
front=[(348,326),(693,290),(693,776),(348,738)]
side=[(693,290),(875,382),(875,867),(693,776)]
poly(front,(103,108,91),INK,2)
poly(side,(65,76,67),INK,2)
# Broken mortar, long wall shadows, engraved hatch directions.
for yy in range(328,760,17):
 x0,x1=350,691
 ratio=(yy-328)/430
 line([(x0,yy),(x1,yy-32+ratio*63)],(78,88,76),.65)
 for xx in range(355+(yy//17%2)*23,692,48):
  py=yy+(xx-x0)/341*(-32+ratio*63)
  line([(xx,py),(xx+R.uniform(-2,2),py+14)],(78,87,76),.7)
hatch_polygon(side,(24,39,36),5,-.85,80)
for _ in range(170):
 x,y=R.uniform(352,687),R.uniform(343,740)
 line([(x,y),(x+R.uniform(2,11),y+R.uniform(-2,1))],R.choice([(119,119,98),(81,91,77)]),.7)
# Roof slopes, slate courses and chimney stacks.
poly([(313,329),(393,207),(659,179),(718,290)],(42,55,51),INK,3)
poly([(659,179),(718,290),(871,385),(805,268)],(34,48,46),INK,2)
for k in range(1,8):
 t=k/8;left=(313+(393-313)*t,329+(207-329)*t);right=(718+(659-718)*t,290+(179-290)*t)
 line([left,right],(87,98,84),.8)
 for q in range(1,12):
  f=q/12;xx=left[0]+(right[0]-left[0])*f;yy=left[1]+(right[1]-left[1])*f
  line([(xx,yy),(xx+5,yy-10)],(28,42,40),.7)
poly([(400,166),(438,162),(438,227),(400,232)],(80,89,75),INK,2)
poly([(438,162),(456,173),(456,223),(438,227)],(51,65,57))
rect((393,157,442,167),(100,107,89),INK)
rect((402,140,412,157),(46,60,54));rect((424,136,435,157),(46,60,54))
poly([(599,125),(629,123),(629,189),(599,192)],(76,87,74),INK,2)
poly([(629,123),(646,133),(646,189),(629,189)],(46,61,54))
line([(595,123),(630,120),(646,130)],(104,112,93),4)
# Eaves and lintels, with chiselled imperfect edges.
poly([(312,329),(718,286),(722,301),(322,347)],(32,45,40))
line([(317,329),(716,289)],(135,135,106),2)
line([(343,346),(693,306)],(125,128,104),1)
line([(345,530),(693,524)],(58,71,59),7)
line([(345,525),(693,519)],(140,137,106),2)
# A lantern-like slit between shutter and frame is the scene's single warm focal point.
def window(x,y,w,h,lit=False):
 poly([(x-7,y-7),(x+w+7,y-10),(x+w+6,y+h+7),(x-7,y+h+7)],(127,127,101),INK,2)
 rect((x,y,x+w,y+h),(30,43,40),INK,2)
 if lit:
  glow(x+w*.62,y+h*.5,w*.85,h*.72,(193,156,85),80)
  rect((x+w*.57,y+4,x+w*.68,y+h-3),(213,189,132))
  rect((x+w*.58,y+5,x+w*.63,y+h-5),(216,194,154))
 # closed shutter boards, narrow seam, rain-wet slats
 poly([(x+1,y+1),(x+w*.55,y+1),(x+w*.54,y+h),(x+1,y+h)],(53,66,54),INK)
 poly([(x+w*.72,y+1),(x+w-1,y),(x+w-1,y+h),(x+w*.72,y+h)],(45,59,50),INK)
 for yy in range(int(y+8),int(y+h),9):
  line([(x+3,yy),(x+w*.51,yy-1)],(88,98,77),.9)
  line([(x+w*.75,yy),(x+w-3,yy-1)],(71,85,66),.8)
 line([(x-10,y+h+10),(x+w+10,y+h+10)],(142,138,108),4)
 poly([(x-8,y+h+13),(x+w+10,y+h+13),(x+w+2,y+h+21),(x-6,y+h+18)],(44,60,50))
window(389,373,81,117,False)
window(549,356,85,125,True)
# Faint warm streak beneath the slit, and the dark entry below.
poly([(596,500),(602,500),(612,521),(600,522)],(122,115,80))
window(389,574,78,106,False)
# Door surround; arched fanlight built with nested ellipses.
ellipse((535,543,655,627),(124,122,95),INK,2)
rect((535,583,655,758),(121,120,94),INK,2)
ellipse((548,555,642,622),(31,44,39),INK,2)
rect((548,590,642,755),(34,47,40),INK,2)
line([(550,591),(640,591)],(117,116,85),2)
for ang in [205,235,270,305,335]:
 a=math.radians(ang);line([(596,591),(596+43*math.cos(a),591+32*math.sin(a))],(106,111,83),1)
for xa in [558,602]:
 for ya,hh in [(606,58),(678,61)]:
  rect((xa,ya,xa+29,ya+hh),(42,55,43),(77,86,61),1)
  line([(xa+4,ya+4),(xa+4,ya+hh-4)],(22,38,33))
ellipse((625,676,630,682),GOLD)
# Stone entrance steps in perspective.
for i in range(3):
 y=753+i*10;poly([(530-i*9,y),(657+i*9,y+5),(669+i*11,y+16),(519-i*10,y+11)],(91-i*9,99-i*8,81-i*6),INK)
 line([(530-i*9,y),(657+i*9,y+5)],(145-i*13,143-i*13,111-i*10),1)
# Right wall side windows and drainpipe.
for y in [421,588]:
 poly([(735,y),(791,y+26),(791,y+113),(735,y+81)],(30,46,42),INK,2)
 line([(761,y+14),(761,y+94)],(83,97,78),2)
 line([(736,y+42),(790,y+69)],(83,97,78),2)
line([(681,307),(684,720),(690,766)],(27,43,37),7)
line([(679,310),(681,718)],(124,126,95),1)
for y in [400,556,690]:line([(674,y),(689,y)],(34,48,39),3)
# Railings along the pavement on the right.
for i in range(7):
 x=715+i*23;y=800+i*9
 line([(x,y),(x,y-107)],(28,44,38),3)
 poly([(x-4,y-106),(x,y-118),(x+4,y-106)],(28,44,38))
line([(710,724),(852,777)],(32,48,39),4)
line([(710,789),(852,840)],(32,48,39),3)
# A foreground gas lamp: fluted iron, small amber pool, no glowing outlines.
glow(189,473,88,117,(171,146,88),48)
poly([(164,447),(212,447),(205,502),(171,502)],(165,148,98),INK,3)
poly([(169,451),(185,451),(185,495),(175,495)],(204,184,127))
poly([(189,451),(205,451),(200,495),(189,495)],(175,159,105))
line([(187,448),(187,501)],(38,52,41),3)
poly([(155,449),(188,424),(221,449)],(34,47,40),INK,2)
line([(162,445),(213,445)],(118,123,91),1)
ellipse((181,414,195,428),(34,47,40))
line([(188,504),(188,927)],(29,45,39),9)
line([(184,511),(184,904)],(116,119,83),1)
for y in [513,529,881,903]:ellipse((180,y,197,y+8),(39,54,43),(103,109,79),1)
poly([(181,906),(195,906),(202,937),(173,937)],(32,48,40),INK)
ellipse((164,932,211,948),(34,49,42),INK)
# Broken golden reflection on wet stones, constrained to irregular streaks.
for _ in range(100):
 y=R.uniform(939,1180);spread=12+(y-939)*.25;x=188+R.gauss(0,spread*.5)
 length=R.uniform(2,12)*(1+(y-940)/150)
 c=blend((87,99,80),(180,155,97),R.random()*.65)
 line([(x-length/2,y),(x+length/2,y-R.uniform(0,1))],c,R.choice([.7,1,1.5]))
# Rain is painted across the midground before the figure, not through opaque walls.
for _ in range(440):
 x=R.uniform(-30,870);y=R.uniform(20,1180);length=R.uniform(5,22)
 if 335<x<690 and 320<y<760 and R.random()<.80:continue
 line([(x,y),(x-5,y+length)],R.choice([(100,115,103),(83,103,95),(112,122,106)]),.6)
# Intruder approaches the door: turned back, brim and high collar obscure face.
# Feet and a long slick coat form a single legible silhouette.
poly([(476,992),(511,966),(534,991),(564,1036),(550,1053),(517,1027)],(33,48,43))
poly([(458,957),(500,949),(493,1020),(472,1046),(448,1048),(449,1038),(467,1010)],(26,40,37),INK,1)
poly([(500,956),(529,961),(536,1007),(553,1032),(553,1043),(530,1045),(506,1019)],(27,41,37),INK,1)
# Coat flared hem and asymmetric shoulders.
poly([(465,782),(487,768),(511,770),(536,791),(550,849),(538,908),(545,980),(516,988),(492,978),(457,989),(444,968),(455,887),(447,837)],(27,41,38),INK,2)
poly([(485,795),(501,790),(510,968),(492,974),(477,959)],(40,54,46))
poly([(467,819),(459,882),(451,962),(465,974),(477,895)],(35,51,44))
poly([(518,798),(535,813),(543,851),(530,902),(517,897),(523,850)],(22,37,34))
line([(470,794),(459,836),(462,866)],(89,101,80),1.2)
line([(495,801),(501,945),(493,966)],(66,82,67),1)
line([(468,873),(458,957)],(65,81,66),.8)
line([(519,915),(530,967)],(73,87,70),.8)
# Hidden hand and collar, no weapon or advanced magical effects.
ellipse((521,892,535,911),(63,76,61),INK,1)
poly([(476,762),(480,786),(502,798),(519,778),(512,761)],(30,43,37),INK)
ellipse((477,733,515,774),(42,54,44),INK,1)
poly([(473,738),(475,709),(507,706),(517,736)],(31,45,39),INK,2)
line([(477,713),(503,710)],(94,102,77),1)
poly([(460,738),(511,732),(528,741),(485,750),(459,746)],(24,39,35),INK,2)
line([(463,739),(507,735)],(92,101,76),1)
hatch_polygon([(466,807),(493,797),(511,963),(457,979)],(16,32,29),6,.6,50)
# Receding mist at street level; softened distant silhouettes, no hard black void.
glow(320,703,120,18,(119,129,112),26)
# Branches crop naturally at top-right: fine calligraphic strokes.
line([(855,6),(792,67),(752,105),(690,129),(642,148)],(36,53,46),5)
line([(790,68),(779,17),(763,-8)],(36,53,46),3)
line([(750,105),(722,53),(683,21),(657,-9)],(36,53,46),3)
line([(713,74),(674,65),(649,41)],(36,53,46),1.4)
line([(690,129),(660,110),(615,113),(579,91)],(36,53,46),1.4)
line([(750,104),(745,149),(719,180)],(36,53,46),2)
# Gentle ink variation, not paper grain: barely perceptible print density.
noise=Image.effect_noise(im.size,7).convert('RGB')
im=Image.blend(im,noise,.035)
# Reserve no frame/label; deliver the exact diary aspect ratio.
out=Path(__file__).resolve().parents[1]/'assets/raster/v0.85.0/preview/battle-moretti-home-study.png'
out.parent.mkdir(parents=True,exist_ok=True)
im=im.filter(ImageFilter.GaussianBlur(.30))
im.save(out,optimize=True)
print(out)
