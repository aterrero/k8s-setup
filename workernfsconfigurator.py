import os

mf = open("manager","r")
mip = mf.read().strip()
mf.close()

os.system("mkdir -p /nfs/general")
os.system("mount {}:/var/nfs/general /nfs/general".format(mip))
