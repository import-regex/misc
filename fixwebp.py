from PIL import Image
from glob import glob
from os import remove
d=input("delete every original .webp file? y/n")
for file in glob(r"*.webp"):
 Image.open(file).save(file.replace(r'.webp',r'.png'))
 if  d=="y":
  remove(file)