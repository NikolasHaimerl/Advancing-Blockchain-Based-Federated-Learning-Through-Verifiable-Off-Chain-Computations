import numpy as np

def ReLU(x):
    return x * (x > 0)

def dReLU(x):
    return 1. * (x > 0)

def sigmoid(x):
  return 1 / (1 + np.exp(-x))


def sigmoid_derivative(x):
    return sigmoid(x) * (1 - sigmoid(x))

def mse(y_true, y_pred,precision=1):
    return np.mean(np.power(y_true-y_pred, 2)/np.power(precision,2))

def mse_prime(y_true, y_pred):
    return 2*(y_pred-y_true)/y_true.size;

class Layer:
    def __init__(self,precision=10**6):
        self.input = None
        self.output = None
        self.precision=precision

    # computes the output Y of a layer for a given input X
    def forward_propagation(self, input):
        raise NotImplementedError

    # computes dE/dX for a given dE/dY (and update parameters if any)
    def backward_propagation(self, output_error, learning_rate):
        raise NotImplementedError

    def set_precision(self,precision):
        self.precision=precision

class FCLayer(Layer):
    # input_size = number of input neurons
    # output_size = number of output neurons
    def __init__(self, input_size, output_size):
        self.weights = None
        self.bias = None
        self.inputSize=input_size
        self.outputSize=output_size

    # returns output for a given input
    def forward_propagation(self, input_data):
        self.input = input_data
        self.output = np.dot(self.input, self.weights)/self.precision + self.bias
        self.output=self.output.astype(int)
        return self.output

    def set_precision(self,precision):
        self.precision=precision

    def set_weights(self,weights):
        self.weights=np.array(weights)
        self.weights=self.weights.T

    def get_weights(self):
        return self.weights.T

    def set_bias(self,bias):
        self.bias=np.array(bias).reshape(1,-1)

    def get_bias(self):
        return self.bias.T

    def backward_propagation(self, output_error, learning_rate):
        input_error = np.dot(output_error, self.weights.T)/self.precision
        input_error=input_error.astype(int)
        weights_error = np.outer(self.input.T, output_error)/self.precision
        weights_error=weights_error.astype(int)

        # dBias = output_error

        # update parameters
        self.weights -= (weights_error/learning_rate).astype(int)
        self.bias -= (output_error/learning_rate).astype(int)
        return input_error

class ActivationLayer(Layer):
    def __init__(self, activation, activation_prime):
        self.activation = activation
        self.activation_prime = activation_prime

    # returns the activated input
    def forward_propagation(self, input_data):
        self.input = input_data
        self.output = self.activation(self.input)
        return self.output

    # Returns input_error=dE/dX for a given output_error=dE/dY.
    # learning_rate is not used because there is no "learnable" parameters.
    def backward_propagation(self, output_error, learning_rate):
        return self.activation_prime(self.input) * output_error


class Network:
    def __init__(self,outputdimension,inputdimension,precision):
        self.layers = []
        self.loss = None
        self.loss_prime = None
        self.input_dimension=inputdimension
        self.output_dimension=outputdimension
        self.precision=precision

    # add layer to network
    def add(self, layer):
        layer.set_precision(precision=self.precision)
        if isinstance(layer, FCLayer):
            weights = np.random.randint(-self.precision, self.precision, size=(self.output_dimension, self.input_dimension))
            bias = np.random.randint(-self.precision, self.precision, size=(self.output_dimension,))
            layer.set_weights(weights)
            layer.set_bias(bias)
        self.layers.append(layer)

    # set loss to use
    def use(self, loss, loss_prime):
        self.loss = loss
        self.loss_prime = loss_prime

    # predict output for given input
    def predict(self, input_data):
        # sample dimension first
        samples = len(input_data)
        input_data = input_data*self.precision
        input_data=input_data.astype(int)
        result = []
        # run network over all samples
        for i in range(samples):
            # forward propagation
            output = input_data[i]
            for layer in self.layers:
                output = layer.forward_propagation(output)
            output=np.argmax(output)+1
            result.append(output)
        return result

    def set_weights(self,weights):
        for layer in self.layers:
            if isinstance(layer,FCLayer):
                layer.set_weights(weights)

    def set_bias(self,bias):
        for layer in self.layers:
            if isinstance(layer,FCLayer):
                layer.set_bias(bias)

    def get_weights(self):
        for layer in self.layers:
            if isinstance(layer, FCLayer):
                return layer.get_weights()

    def get_bias(self):
        for layer in self.layers:
            if isinstance(layer, FCLayer):
                return layer.get_bias()

    def set_precision(self,precision):
        self.precision=precision
        for layer in self.layers:
            if isinstance(layer, FCLayer):
                return layer.set_precision(precision)
    # train the network
    def fit(self, x_train, y_train, epochs, learning_rate):
        # sample dimension first
        samples = len(x_train)
        # training loop
        for i in range(epochs):
            err = 0
            for j in range(samples):
                # forward propagation
                output = x_train[j]*self.precision
                output=output.astype(int)
                y_true=np.zeros(self.output_dimension)
                y_true[y_train[j]-1]=self.precision
                for layer in self.layers:
                    output = layer.forward_propagation(output)
                # compute loss (for display purpose only)
                err += self.loss(y_true, output,precision=self.precision)
                # backward propagation
                error = self.loss_prime(y_true, output).astype(int)
                for layer in reversed(self.layers):
                    error = layer.backward_propagation(error, learning_rate)

            # calculate average error on all samples
            err /= samples
            #print('epoch %d/%d   error=%f' % (i+1, epochs, err))

