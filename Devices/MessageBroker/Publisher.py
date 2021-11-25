import pika

class Publisher:
    def __init__(self):
        self.queue=None
        self.connection= pika.BlockingConnection(pika.ConnectionParameters('localhost'))
        self.channel=self.connection.channel()

    def declare_queue(self,name):
        self.channel.queue_declare(queue=name)
    def publish_data(self,queueName,data):
        self.channel.basic_publish(exchange="",routing_key=queueName,body=data)
    def close_connection(self):
        self.connection.close()

