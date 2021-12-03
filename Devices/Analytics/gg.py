import string

import matplotlib
import os.path

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
activity_wording={
    1:"Walking Stairs",
    2:"Walking",
    3:"Running",
    4: "Elliptical Trainer",
    5: "Cycling",
    6: "Rowing"
}



markers=[".","x","2","1","X","+","d","3"]
BASE_PATH="/home/nikolas/MEGA/Workplace/Informatik/Masterarbeit/Implementation/PythonProject/MasterThesis_SoftwareEngineering/Devices/MiddleWare/Analytics"

#%%

participants=8
batchsize=40

#%%

data={}
for device in range(1,participants+1):
    temp={}
    temp['Round_Classification_Report']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Classification_Report")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Gas']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Gas")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Proof_Time']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Proof_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Score']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Score")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Time']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Training_Local_Time']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Training_Local_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
    temp['Round_Update_Blockchain_Time']=pd.read_csv(os.path.join(os.path.join(os.path.join(os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participants)),"BatchSize_"+str(batchsize)),"Device_"+str(device)),"Round_Update_Blockchain_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
    data['Device_'+str(device)]=temp

#%%
def calc_devices_mean(data,kpi,x):
    df=pd.DataFrame()
    for participant in range(1,len(data)+1):
        g=data["Device_"+str(participant)]
        df=pd.concat([df,g[kpi][x]])
    by_row_index = df.groupby(df.index)
    df_means = by_row_index.mean()
    return df_means

def plot_gas(data):
    plt.xlabel("Update-Round")
    plt.ylabel("Gas-Costs")
    plt.boxplot(data["Gas-Costs"])
def plot_proof_time(data,marker=markers[0]):
    plt.xlabel("Update-Round")
    plt.ylabel("Time-Taken")
    plt.plot(data["Round-Number"],data["Time-Taken"],marker=marker,linewidth=0.5,markevery=10)
def plot_training_local_time(data):
    plt.xlabel("Update-Round")
    plt.ylabel("Time-Taken")
    plt.plot(data["Round-Number"],data["Time-Taken"],linewidth=0.5)
def plot_round_time(data):
    plt.xlabel("Update-Round")
    plt.ylabel("Time-Taken")
    plt.plot(data["Round-Number"],data["Time-Taken"],linewidth=0.5)
def plot_score(data):
    plt.xlabel("Update-Round")
    plt.ylabel("Score")
    plt.plot(data["Round-Number"],data["Score"],linewidth=0.5)
def plot_update_blockchain_time(data,marker=markers[0]):
    plt.xlabel("Update-Round")
    plt.ylabel("Time-Taken")
    z = np.polyfit(data["Round-Number"], data["Time-Taken"], 1)
    p = np.poly1d(z)
    plt.scatter(data["Round-Number"],data["Time-Taken"])
    plt.plot(data["Round-Number"],p(data["Round-Number"]),marker=marker,linewidth=0.5,markevery=10)

def plot_classification_report(data):
    plt.xlabel("Update-Round")
    plt.ylabel("Precision")
    for i in range(0,len(["1","2","3","4","5","6"])):
        plt.plot(data["Round-Number"],data[str(i+1)],marker=markers[i],linewidth=0.5,markevery=10)
    plt.legend(["Walking Stairs", "Walking", "Running", "Elliptical Trainer", "Cycling", "Rowing"])

#%%

for device in data.keys():
    df=data[device]
    plt.figure(figsize=(15,10))
    plot_gas(df["Round_Gas"])
    plt.show()

#%%

plt.figure(figsize=(15,10))
for device in data.keys():
    df=data[device]
    plot_training_local_time(df["Round_Training_Local_Time"])
plt.legend(list(data.keys()))

#%%

plt.figure(figsize=(15,10))
for device in data.keys():
    df=data[device]
    plot_score(df["Round_Score"])
plt.legend(list(data.keys()))

#%%

plt.figure(figsize=(15,10))
for j in range(0,len(data.keys())):
    device=list((data.keys()))[j]
    df=data[device]
    plot_update_blockchain_time(df["Round_Update_Blockchain_Time"],marker=markers[j])
plt.legend(list(data.keys()))

#%%

for device in data.keys():
    df=data[device]
    plt.figure(figsize=(15,10))
    plot_classification_report(df["Round_Classification_Report"])
    plt.show()

#%%

plt.figure(figsize=(15,10))
for j in range(0,len(data.keys())):
    device=list((data.keys()))[j]
    df=data[device]
    plot_proof_time(df["Round_Proof_Time"],marker=markers[j])
plt.legend(list(data.keys()))

#%%

batchsizes=[10,20,30,40]
participants=range(8,9)
devices=range(1,9)
#%%

data={}
for participant in participants:
    temp_p={}
    for batchsize in batchsizes:
        temp_b={}
        for device in range(1,participant+1):
            temp_d={}
            p=os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participant))
            p=os.path.join(  p,"BatchSize_"+str(batchsize))
            p=os.path.join(  p,"Device_"+str(device))
            try:
                temp_d['Round_Classification_Report']=pd.read_csv(os.path.join(p,"Round_Classification_Report")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Gas']=pd.read_csv(os.path.join(  p,"Round_Gas")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Proof_Time']=pd.read_csv(os.path.join(  p,"Round_Proof_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Score']=pd.read_csv(os.path.join(  p,"Round_Score")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Time']=pd.read_csv(os.path.join(  p,"Round_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Training_Local_Time']=pd.read_csv(os.path.join(  p,"Round_Training_Local_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Update_Blockchain_Time']=pd.read_csv(os.path.join(  p,"Round_Update_Blockchain_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_b['Device_'+str(device)]=temp_d
            except FileNotFoundError:
                print("Not found")
        temp_p['BatchSize_'+str(batchsize)]=temp_b
    data['Participants_'+str(participant)]=temp_p

#%%

for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    for j in range(0, len(batches.keys())):
        b = list((batches.keys()))[j]
        batch=batches[b]
        if bool(batch):
            t=calc_devices_mean(batch,"Round_Proof_Time","Time-Taken")
            d=pd.DataFrame()
            d["Round-Number"]=range(1,len(t)+1)
            d["Time-Taken"]=t
            plot_proof_time(d,marker=markers[j])
    plt.ylabel("Time-Taken [Seconds]")
    plt.legend(list(batches.keys()))
    plt.show()

#%%



#%%

for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    for j in range(0, len(batches.keys())):
        b = list((batches.keys()))[j]
        batch=batches[b]
        if bool(batch):
            plt.rc('pgf', texsystem='pdflatex')
            t=calc_devices_mean(batch,"Round_Proof_Time","Time-Taken")
            d=pd.DataFrame()
            d["Round-Number"]=range(1,len(t)+1)
            d["Time-Taken"]=t
            plot_proof_time(d,marker=markers[j])
    plt.ylabel("Time-Taken [Seconds]")
    plt.legend(list(batches.keys()))
    plt.savefig('ProofTimes.pgf')

#%%



#%%

# for participant in data.keys():
#     batches=data[participant]
#     plt.figure(figsize=(15,10))
#     for b in batches.keys():
#         batch=batches[b]
#         if bool(batch):
#             g=batch["Device_1"]
#             t=g["Round_Gas"]
#             plot_gas(t)
#     plt.legend(list(batches.keys()))
#     plt.show()

#%%

for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    dict={}
    df=pd.DataFrame()
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            t=calc_devices_mean(batch,"Round_Gas",'Gas-Costs')
            dict[b]=t
    for key in dict.keys():
        df[key]=dict[key]
    df.plot(kind='box',showmeans=True)
    plt.ylabel("Gas Costs [ETH]")
    plt.savefig('gascosts.pgf')

#%%
for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    plt.rc('pgf', texsystem='pdflatex')
    dict={}
    df=pd.DataFrame()
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            t=calc_devices_mean(batch,"Round_Update_Blockchain_Time","Time-Taken")
            dict[b]=t
    for key in dict.keys():
        df[key]=dict[key]
    df.plot(kind='box',showmeans=True)
    plt.ylabel("Time-Taken [Seconds]")
    plt.savefig('roundupdateBCtime.pgf')


#%%


for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    df=pd.DataFrame(dict.items(),columns=dict.keys())
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            g=calc_devices_mean(batch,"Round_Update_Blockchain_Time",'Time-Taken')
            dict[b]=g
    for key in dict.keys():
        df[key]=dict[key]
    df.plot(kind='box',showmeans=True)
    plt.ylabel("Time-Taken [Seconds]")
    plt.savefig('roundupdateBCtimeBP.pgf')

#%%
for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    df=pd.DataFrame(dict.items(),columns=dict.keys())
    for b in batches.keys():
        batch=batches[b]
        if bool(batch) :
            g=calc_devices_mean(batch,"Round_Proof_Time",'Time-Taken')
            dict[b]=g
    for key in dict.keys():
        df[key]=dict[key]
    df.plot(kind='box',showmeans=True)
    plt.ylabel("Time-Taken [Seconds]")
    plt.savefig('roundProof_Time.pgf')
    plt.show()


for participant in data.keys():
    batches=data[participant]
    plt.figure(figsize=(15,10))
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    df=pd.DataFrame(dict.items(),columns=dict.keys())
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            g=calc_devices_mean(batch,"Round_Training_Local_Time",'Time-Taken')
            dict[b]=g
    for key in dict.keys():
        df[key]=dict[key]
    df.plot(kind='box',showmeans=True)
    plt.legend(list(batches.keys()))
    plt.ylabel("Time-Taken [Seconds]")
    plt.savefig('round_training_local.pgf')
    plt.show()

for j in range(0, len(data.keys())):
    participant = list((data.keys()))[j]
    batches=data[participant]
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    df=pd.DataFrame(dict.items(),columns=dict.keys())
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            g=calc_devices_mean(batch,"Round_Score",'Score')
            dict[b]=g
    for key in dict.keys():
        df[key]=dict[key]
    for i in range(0,len(df.columns)):
        d=df[df.columns[i]]
        d.plot(marker=markers[i],linewidth=0.5,markevery=10)
    plt.legend(df.columns)
    plt.xlabel("Round Number")
    plt.ylabel("Accuracy Score")
    plt.savefig('roundScore.pgf')
    plt.show()


def export_legend(legend, filename="legend.png", expand=[-5,-5,5,5]):
    fig  = legend.figure
    fig.canvas.draw()
    bbox  = legend.get_window_extent()
    bbox = bbox.from_extents(*(bbox.extents + np.array(expand)))
    bbox = bbox.transformed(fig.dpi_scale_trans.inverted())
    fig.savefig(filename, dpi="figure", bbox_inches=bbox)


for participant in data.keys():
    batches=data[participant]
    #plt.figure(figsize=(3,3))
    dict={}
    plt.rc('pgf', texsystem='pdflatex')
    df=pd.DataFrame(dict.items(),columns=dict.keys())
    for b in batches.keys():
        batch=batches[b]
        if bool(batch):
            g=calc_devices_mean(batch,"Round_Classification_Report", ["1", "2", "3", "4", "5", "6"])
            dict[b]=g
    fig, axs = plt.subplots(2, 2,sharex=True, sharey=True,figsize=(8,5))
    ls=[]
    for j in range(0,len(dict.keys())):
        key=list(dict.keys())[j]
        k=dict[key]
        x,y=(None,None)
        if j==0:
            x,y=(0,0)
        if j==1:
            x=0
            y=1
        if j==2:
            x=1
            y=0
        if j==3:
            x=1
            y=1
        l=None
        for i in range(0, len(["1", "2", "3", "4", "5", "6"])):
            ls.append(axs[x][y].plot(range(1,len(dict[key])+1), k[str(i + 1)], marker=markers[i],linewidth=0.5,markevery=50)[0])
        axs[x][y].title.set_text(key)
       # plt.ylabel("Accuracy Score")
       # plt.xlabel("Round Number")
        #plt.legend(ls,,loc="upper right")
    plt.subplots_adjust(wspace=0, hspace=0.2)
    axs[0][0].set_ylabel("Accuracy Score")
    axs[1][0].set_ylabel("Accuracy Score")
    axs[1][0].set_xlabel("Round Number")
    axs[1][1].set_xlabel("Round Number")
    fig.legend(ls, ["Walking Stairs", "Walking", "Running", "Elliptical Trainer", "Cycling", "Rowing"], loc='upper center',ncol=6)
    fig.savefig(f'roundScoreClasses.pgf')
    plt.show()

batchsizes=[10,20,30,40]
participants=range(2,9,2)
devices=range(1,9)
#%%

data={}
for participant in participants:
    temp_p={}
    for batchsize in batchsizes:
        temp_b={}
        for device in range(1,participant+1):
            temp_d={}
            p=os.path.join(BASE_PATH,"NumberOfParticipants_"+str(participant))
            p=os.path.join(  p,"BatchSize_"+str(batchsize))
            p=os.path.join(  p,"Device_"+str(device))
            try:
                temp_d['Round_Classification_Report']=pd.read_csv(os.path.join(p,"Round_Classification_Report")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Gas']=pd.read_csv(os.path.join(  p,"Round_Gas")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Proof_Time']=pd.read_csv(os.path.join(  p,"Round_Proof_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Score']=pd.read_csv(os.path.join(  p,"Round_Score")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Time']=pd.read_csv(os.path.join(  p,"Round_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Training_Local_Time']=pd.read_csv(os.path.join(  p,"Round_Training_Local_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_d['Round_Update_Blockchain_Time']=pd.read_csv(os.path.join(  p,"Round_Update_Blockchain_Time")).drop_duplicates(subset=["Round-Number"]).reset_index()
                temp_b['Device_'+str(device)]=temp_d
            except FileNotFoundError:
                print("Not found")
        temp_p['BatchSize_'+str(batchsize)]=temp_b
    data['Participants_'+str(participant)]=temp_p
dict={}
for participant in data.keys():
    batches=data[participant]
    plt.rc('pgf', texsystem='pdflatex')
    for b in batches.keys():
        batch=batches[b]
        g = calc_devices_mean(batch, "Round_Score", "Score")
        amount=int(participant.strip(string.ascii_letters).replace("_",""))*int(b.strip(string.ascii_letters).replace("_",""))
        if bool(batch):
            if not str(amount) in dict.keys():
                df=pd.DataFrame()
                df[participant+" | "+b]=g
                dict[str(amount)]=df
            else:
                dict[str(amount)][participant+" | "+b]=g
for j in range(0,len(dict.keys())):
    key=list((dict.keys()))[j]
    k=dict[key]
    if len(k.columns)>1:
        plt.plot(range(1,len(dict[key])+1),k,linewidth=0.5,markevery=10)
        plt.ylabel("Accuracy Score")
        plt.xlabel("Round Number")
        plt.legend(k.columns)
        plt.savefig(f'participantsVSBatchsize_{key}.pgf')
        plt.show()


dict = {}
for participant in data.keys():
    batches = data[participant]
    plt.rc('pgf', texsystem='pdflatex')
    for b in batches.keys():
        batch = batches[b]
        g = calc_devices_mean(batch, "Round_Score", "Score")
        if bool(batch):
            if not b in dict.keys():
                df = pd.DataFrame()
                df[participant + " | " + b] = g
                dict[b] = df
            else:
                dict[b][participant + " | " + b] = g
fig, axs = plt.subplots(2, 2, sharex=True, sharey=True, figsize=(8, 5))
ls = []

for j in range(0, len(dict.keys())):
    key = list(dict.keys())[j]
    k = dict[key]
    x, y = (None, None)
    if j == 0:
        x, y = (0, 0)
    if j == 1:
        x = 0

        y = 1
    if j == 2:
        x = 1
        y = 0
    if j == 3:
        x = 1
        y = 1
    ls.append(axs[x][y].plot(range(1, len(dict[key]) + 1), k, linewidth=0.5, markevery=10)[0])
    axs[x][y].title.set_text(key)
    axs[x][y].legend(k.columns)

# plt.ylabel("Accuracy Score")
# plt.xlabel("Round Number")
# plt.legend(ls,,loc="upper right")
plt.subplots_adjust(wspace=0, hspace=0.2)
axs[0][0].set_ylabel("Accuracy Score")
axs[1][0].set_ylabel("Accuracy Score")
axs[1][0].set_xlabel("Round Number")
axs[1][1].set_xlabel("Round Number")
fig.savefig(f'participants_in_sameBatchsize.pgf')
plt.show()

