import torch
from torch import nn
from torch.autograd import Variable

class LayerNode:
    def __init__(self, name, layer, x):
        self.layer_type = layer.__class__.__name__
        self.weights = layer.weight
        self.input_size = x.size()
        self.weight_size = layer.weight.size()
        self.output_size = layer(x).size()
        self.name = name

# Example usage
if __name__ == "__main__":
    # Create a random input tensor
    x = Variable(torch.randn(1,128,20))

    # Initialize an empty list to store the layer info objects
    node_list = []

    model = nn.Sequential(nn.Linear(20, 40), nn.Linear(40, 50))

    # x = torch.randn(128, 20)

    output = model(x)

    print(output.size())

    # Loop through each layer in the model
    for name,layer in model.named_children():
        if isinstance(layer, torch.nn.modules.conv.Conv2d) or isinstance(layer, torch.nn.modules.linear.Linear):
            new_node = LayerNode(name,layer, x)
            node_list.append(new_node)
            x = layer(x)

    print(x)