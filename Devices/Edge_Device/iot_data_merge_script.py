import random

import pandas as pd
import numpy as np
import os
import pickle
import re

from sklearn.model_selection import train_test_split

source="data/iot_data"
def whole_merge():
   a={
      "a01":[],"a02":[],"a03":[],"a04":[],"a05":[],"a06":[],"a07":[],"a08":[],"a09":[],"a10":[],"a11":[],"a12":[],"a13":[],"a14":[],"a15":[],"a16":[],"a17":[],"a18":[],"a19":[]
   }

   b={
      "a01": 1, "a02": 2, "a03": 3, "a04": 4, "a05": 5, "a06": 6, "a07": 7, "a08": 8, "a09": 9, "a10": 10,
      "a11": 11, "a12": 12, "a13": 13, "a14": 14, "a15": 15, "a16": 16, "a17": 17, "a18": 18, "a19": 19
   }
   out="data/outfile_merged.txt"

   for root, dirs, files in os.walk(source, topdown=True):
      for name in files:
         for activity in a.keys():
            if activity in root:
               data = np.loadtxt(os.path.join(root,name),delimiter=",")
               a[activity].extend(data)

   with open(out,"w") as f:
      for key in b.keys():
         d=a[key]
         for row_idx in range(0,len(d)):
            tp=d[row_idx]
            tp=list(map(str,tp))
            k=b[key]
            [f.write(x+",") for x in tp]
            f.write(str(k))
            f.write("\n")
   df=pd.read_csv(out,sep=",",header=None)
   df.head()
   df=df.sample(frac=1)
   train=df.iloc[:int(0.9*len(df))]
   test=df.iloc[int(0.9*len(df)):]
   train.to_csv("/home/nikolas/MEGA/Workplace/Informatik/Masterarbeit/Implementation/PythonProject/MasterThesis_SoftwareEngineering/Devices/Edge_Device/data/train.txt",index=False,header=False)
   test.to_csv("/home/nikolas/MEGA/Workplace/Informatik/Masterarbeit/Implementation/PythonProject/MasterThesis_SoftwareEngineering/Devices/Edge_Device/data/test.txt",index=False,header=False)

def divide_participants():
   p = {
      "p1": [], "p2": [], "p3": [], "p4": [], "p5": [], "p6": [], "p7": [], "p8": []
   }
   for root, dirs, files in os.walk(source, topdown=True):
      for name in files:
         for participant in p.keys():
            if participant in root:
               activity_search = re.search("a\d\d", root)
               data = np.loadtxt(os.path.join(root, name), delimiter=",")
               temp=[]
               if activity_search:
                  activity = activity_search.group(0)
                  for datapoint in range(len(data)):
                     g=list(data[datapoint])
                     s=[int(s) for s in activity if s.isdigit()]
                     s = ''.join(str(e) for e in s)
                     g.append(int(s))
                     temp.append(g)
               data=temp
               p[participant].extend(data)
   with open("/home/nikolas/MEGA/Workplace/Informatik/Masterarbeit/Implementation/PythonProject/MasterThesis_SoftwareEngineering/Devices/Edge_Device/data/test_file.txt",
             "w") as t:
      for i in range(1,9):
         device="Device_"+str(i)
         out_path=os.path.join("data", device)
         if not os.path.exists(out_path):
            os.makedirs(out_path)
         with open(os.path.join(out_path,"device_data.txt"),"w") as f:
            d = p["p"+str(i)]
            np.random.shuffle(d)
            for row_idx in range(int(0.9*len(d))):
               tp = d[row_idx]
               tp = list(map(str, tp))
               [f.write(tp[x] + ",") for x in range(len(tp)) if x!=len(tp)-1]
               f.write(tp[len(tp)-1])
               f.write("\n")
            for row_idx in range(int(0.9*len(d)),len(d)):
               tp = d[row_idx]
               tp = list(map(str, tp))
               [t.write(tp[x] + ",") for x in range(len(tp)) if x != len(tp) - 1]
               t.write(tp[len(tp) - 1])
               t.write("\n")



if __name__ == '__main__':
   #divide_participants()
   whole_merge()