import os
import pandas as pd
import time
from Devices.MessageBroker.Publisher import Publisher
from Devices.utils.utils import read_yaml


class EdgeDevice:
    def __init__(self,DeviceName,config_file):
        self.config=config_file
        self.datasource=os.path.join(os.path.join(self.config["DEFAULT"]["TrainFilePath"],DeviceName+"/device_data.txt"))
        self.publisher=Publisher()
        self.queueName=self.config["DEFAULT"]["QueueBase"]+DeviceName
        self.publisher.declare_queue(self.queueName)
        self.data=None
        self.init_dataset()

    def init_dataset(self):
        self.data = pd.read_csv(
            self.datasource, names=
            ["T_xacc", "T_yacc", "T_zacc", "T_xgyro", "T_ygyro", "T_zgyro", "T_xmag", "T_ymag", "T_zmag",
             "RA_xacc", "RA_yacc", "RA_zacc", "RA_xgyro", "RA_ygyro", "RA_zgyro", "RA_xmag", "RA_ymag", "RA_zmag",
             "LA_xacc", "LA_yacc", "LA_zacc", "LA_xgyro", "LA_ygyro", "LA_zgyro", "LA_xmag", "LA_ymag", "LA_zmag",
             "RL_xacc", "RL_yacc", "RL_zacc", "RL_xgyro", "RL_ygyro", "RL_zgyro", "RL_xmag", "RL_ymag", "RL_zmag",
             "LL_xacc", "LL_yacc", "LL_zacc", "LL_xgyro", "LL_ygyro", "LL_zgyro", "LL_xmag", "LL_ymag", "LL_zmag",
             "Activity"]
                    )
        self.data.fillna(inplace=True, method='backfill')
        self.data.dropna(inplace=True)
        self.data.drop(columns= ["T_xacc", "T_yacc", "T_zacc", "T_xgyro","T_ygyro","T_zgyro","T_xmag", "T_ymag", "T_zmag","RA_xacc", "RA_yacc", "RA_zacc", "RA_xgyro","RA_ygyro","RA_zgyro","RA_xmag", "RA_ymag", "RA_zmag","RL_xacc", "RL_yacc", "RL_zacc", "RL_xgyro","RL_ygyro","RL_zgyro" ,"RL_xmag", "RL_ymag", "RL_zmag","LL_xacc", "LL_yacc", "LL_zacc", "LL_xgyro","LL_ygyro","LL_zgyro" ,"LL_xmag", "LL_ymag", "LL_zmag"],inplace=True)
        activity_mapping = self.config["DEFAULT"]["ActivityMappings"]
        activity_encoding = self.config["DEFAULT"]["ActivityEncoding"]
        filtered_activities = self.config["DEFAULT"]["Activities"]
        for key in activity_mapping.keys():
            self.data.loc[ self.data['Activity'] == key,'Activity'] = activity_mapping[key]
        self.data = self.data[self.data['Activity'].isin(filtered_activities)]
        for key in activity_encoding.keys():
            self.data.loc[self.data['Activity'] == key, 'Activity'] = activity_encoding[key]


    def next_batch(self):
        p=self.config["DEFAULT"]["NumberOfSamplesGenerated"]
        batch=self.data.sample(p)
        return batch

    def start_EdgeDevice(self):
        while True:
            nextbatch=self.next_batch()
            self.publisher.publish_data(self.queueName,nextbatch.to_csv())
            time.sleep(float(self.config["DEFAULT"]["IntervalDataGenerator"]))
    def y_name(self):
        return "Activity"

