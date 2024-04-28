import numpy as np

# Calculate no. of cycles for 4 dataflows
# input stationary, output stationary, weight stationary, row stationary
# Account for tiling 
# Given, convolution operation for input size (X*Y), filter size (R*S), no. of. channels (C), no. of filters (K)
# Systolic array size (array_height * array_width)
# Complete the functions as per the instructions
# Assume no padding and strides = 1

class dataflow:
    def __init__(self, X, Y, R, S, C, K, array_height, array_width):

        self.X = X
        self.Y = Y
        
        self.R = R
        self.S = S

        self.C = C
        self.K = K

        self.array_height = array_height
        self.array_width = array_width


        self.rs_compute_cycles = 0
        self.ws_compute_cycles = 0
        self.is_compute_cycles = 0
        self.os_compute_cycles = 0

        

    # For row stationary, following parameters are constant
    # R = S = array_height = array_width = 3
    def row_stationary(self):
        # R = S = array_height = array_width = 3
        # Weight filling time = S = 3 cycles
        # Cycles for partial sum reduc-on = R = 3 cycles
        # Cycles for inputs to stream before calculation starts = 3
        # Assume the PE calculation: (i1*f1 + i2*f2 + i3*f3) is done in 1 cycle

        start_cycles = 3 + 3 + 3  
        Nrows = np.ceil(self.S * self.K / self.array_height)
        Ncolumns = np.ceil((self.Y - self.S + 1) * self.C/self.array_height)
        inputs_Nfilters = self.X - self.R + 1

        #(start_cycles + Nfilterinps) * np.ceil(nRows / 3) * self.K * self.C
        self.rs_compute_cycles = (start_cycles + inputs_Nfilters) * Nrows * Ncolumns
        
        return self.rs_compute_cycles
        
   
    # Nfilter : Number of convolution filters
    # Nofmap: Number of OFMAP pixels generated by filter
    # Wconv : Number of partial sums generated per output pixels

    #                  Spatial Rows (SR) | Spatial Columns (SC) | Temporal (T)
    # Output Stationary: Nofmap | Nfilter | Wconv
    # Weight Stationary: Wconv | Nfilter | Nofmap
    # Input Stationary: Wconv | Nofmap | Nfilter

    def input_stationary(self):

        #Input Stationary: Wconv(SR) | Nofmap(SC) | Nfilter(T)

        Nofmap = (self.X - self.R + 1) * (self.Y - self.S + 1)
        Nfilter = self.K
        Wconv = self.C * self.R * self.S
        SR = Wconv
        SC = Nofmap
        T = Nfilter

        sr_h = np.ceil(SR / self.array_height)
        sc_w = np.ceil(SC / self.array_width)
        self.is_compute_cycles = ((2*self.array_height) + self.array_width + T - 2) * sr_h * sc_w - 1
        return self.is_compute_cycles
 

    def output_stationary(self):

        #Output Stationary: Nofmap(SR) | Nfilter(SC) | Wconv(T)

        Nofmap = (self.X - self.R + 1) * (self.Y - self.S + 1)
        Nfilter = self.K
        Wconv = self.C * self.R * self.S
        SR = Nofmap
        SC = Nfilter
        T = Wconv

        sr_h = np.ceil(SR / self.array_height)
        sc_w = np.ceil(SC / self.array_width)     
        self.os_compute_cycles = ((2*self.array_height) + self.array_width + T - self.array_height - 2) * sr_h * sc_w - 1
        return self.os_compute_cycles
        

    def weight_stationary(self):

        #Weight Stationary: Wconv(SR) | Nfilter(SC) | Nofmap(T)

        Nofmap = (self.X - self.R + 1) * (self.Y - self.S + 1) 
        Nfilter = self.K
        Wconv = self.C * self.R * self.S
        SR = Wconv
        SC = Nfilter
        T = Nofmap

        sr_h = np.ceil(SR / self.array_height)
        sc_w = np.ceil(SC / self.array_width)
        self.ws_compute_cycles = ((2*self.array_height) + self.array_width + T - 2) * sr_h * sc_w - 1
        return self.ws_compute_cycles