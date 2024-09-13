#Use this script to rename your Gcodes in alphanumeric order by their modification time. Makes sure the newest file appears on top of the file browser on your 3D printer

import os
import ctypes
from glob import glob

drives = []
for indexisinuse in enumerate(reversed(f"{ctypes.cdll.kernel32.GetLogicalDrives():b}")):
 #indexisinuse[0]= alphabetical index; [1]= is in use
 drive_letter=f"{chr(65 + indexisinuse[0])}:\\"
 if indexisinuse[1] and ctypes.windll.kernel32.GetDriveTypeW(drive_letter) == 2:  #type 2 means removable drive
  drives.append(drive_letter)
  
print(drives)
for file in [file for drive in drives for file in glob(drive+"*.gcode")]:
 print (f'renaming {file}')
 try:
  os.rename(file,"E:\\"+str(os.path.getmtime(file))+".gcode")
 except OSError:
  print(f"can't rename {file}. file might be broken idk")