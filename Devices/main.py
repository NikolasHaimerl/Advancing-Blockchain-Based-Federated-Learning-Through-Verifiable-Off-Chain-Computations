import sys
import threading
import time
from Devices.MiddleWare.BlockChainClient import BlockChainConnection
from Devices.utils.utils import read_yaml
from Edge_Device.EdgeDevice import EdgeDevice
from MiddleWare.Middleware import MiddleWare

def start_Device(deviceName,accountNr,blockchain_connection,config_file):
    edgeDevice = EdgeDevice(deviceName, config_file=config_file)
    thread = threading.Thread(target=edgeDevice.start_EdgeDevice)
    thread.start()
    middleware = MiddleWare(blockchain_connection=blockchain_connection,deviceName=deviceName, accountNR=accountNr,configFile=config_file)
    middleware.start_Middleware()


if __name__ == '__main__':
    config_file = read_yaml("/home/nikolas/MEGA/Workplace/Informatik/Masterarbeit/Implementation/PythonProject/MasterThesis_SoftwareEngineering/CONFIG.yaml")
    blockchain_connection=BlockChainConnection(config_file=config_file)
    blockchain_connection.connect()
    for i in range(config_file["DEFAULT"]["NumberOfParticipants"]):
        thread=threading.Thread(target= start_Device,args=["Device_"+str(i+1),i,blockchain_connection,config_file])
        thread.start()
        time.sleep(1)

