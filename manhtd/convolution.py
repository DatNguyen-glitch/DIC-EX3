import numpy as np

def convolve_2d(image, kernel):
	kernel_height, kernel_width = kernel.shape
	image_height, image_width = image.shape
	
	# Define the output matrix
	output_height = image_height - kernel_height + 1
	output_width = image_width - kernel_width + 1
	output = np.zeros((output_height, output_width))
	
	# Perform the convolution
	for i in range(output_height):
		for j in range(output_width):
			output[i, j] = np.sum(image[i:i+kernel_height, j:j+kernel_width] * kernel)
		
	return output

# 14x14 data matrix (example)
data_1d = np.arange (101, 297)
data = data_1d.reshape((14, 14))
# data = np.random.rand(14, 14)

# 3x3 filter (example)

# kernel_1d = np.random.randint(1, 100, size=9)
kernel_1d = np.arange (1, 10)
kernel = kernel_1d.reshape((3, 3))
# Convolve the data with the filter
result = convolve_2d(data, kernel)

result_int = result.astype(int)


with open('input.txt', 'w') as file:
	file.write(f"1\n\n")

with open('input.txt', 'a') as file:
	for item in data_1d:
		file.write(f"{item} ")
	file.write(f"\n\n")

with open('input.txt', 'a') as file:
	for item in kernel_1d:
		file.write(f"{item} ")
	file.write(f"\n\n")

with open('output.txt', 'a') as file:
	for item in result_int.flatten():
		file.write(f"{item} ")
	file.write(f"\n\n")


print(kernel)
print(data)
print(result_int)

