# Use an official base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim

# Set the working directory
WORKDIR /app

# Copy files into the container
COPY . /app

# Expose a port (if needed)
EXPOSE 8080

# Define the command to run the application
CMD ["bash"]

