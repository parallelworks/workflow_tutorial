import ray
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

# Define a simple neural network
class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.flatten = nn.Flatten()
        self.fc = nn.Linear(28 * 28, 10)  # MNIST: 28x28 images to 10 classes

    def forward(self, x):
        x = self.flatten(x)
        x = self.fc(x)
        return x

# Training function
@ray.remote(num_gpus=1)  # Request 1 GPU
def train_task():
    # Load MNIST dataset
    transform = transforms.ToTensor()
    train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True)

    # Set up model, loss, and optimizer
    model = SimpleNet().to('cuda')
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.SGD(model.parameters(), lr=0.01)

    # Training loop (3 epochs)
    for epoch in range(3):
        total_loss = 0
        for data, target in train_loader:
            data, target = data.to('cuda'), target.to('cuda')
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        avg_loss = total_loss / len(train_loader)
        print(f"Epoch {epoch+1}, Loss: {avg_loss:.4f}")
    return {"final_loss": avg_loss}

# Main function
def main():
    # Initialize Ray
    ray.init(ignore_reinit_error=True)

    # Run training task
    result = ray.get(train_task.remote())
    print("Training completed:", result)

if __name__ == "__main__":
    main()