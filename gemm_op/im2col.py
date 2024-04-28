import torch
import torch.nn.functional as F
import numpy as np
import matplotlib.pyplot as plt

from PIL import Image


def im2col(input, kernel):
    # Unfold the image and filter
    img_unfolded = F.unfold(input.float(), kernel_size=kernel.shape[2:]).transpose(1, 2)
    kernel = kernel.view(kernel.size(0), -1).t()
    return img_unfolded, kernel


def read_image(path):
    img = Image.open(path)

    if img.mode != 'L':
        img = img.convert('L')

    img = np.array(img)
    img = torch.tensor(img, dtype=torch.int8)

    return img


img = read_image('gemm_op/100.png')

# Display the image
plt.imshow(img, cmap='gray')
plt.show()

# Convert the image to a tensor
img = torch.tensor(img, dtype=torch.int16)


# Creating an edge detection filter
edge_filter = torch.tensor([[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]], dtype=torch.int16)

edge_filter = edge_filter.reshape(1, 1, edge_filter.shape[0], edge_filter.shape[1])
img = img.reshape(1, 1, img.shape[0], img.shape[1])


# Applying the filter to the image
edge_detected = torch.nn.functional.conv2d(img.float(), edge_filter.float())

# Display the edge detected image
plt.imshow(edge_detected.squeeze(0).squeeze(0).detach().numpy(), cmap='gray')
plt.show()

img_unfolded, edge_filter = im2col(img, edge_filter)

print(img_unfolded.shape)
print(edge_filter.shape)


out_unf = img_unfolded.float().matmul(edge_filter.float())
out_unf = out_unf.reshape(1,1,26,26)
# Display the edge detected image
plt.imshow(out_unf.squeeze(0).squeeze(0).detach().numpy(), cmap='gray')
plt.show()