A HELM chart and custom image that can be used to deploy developer workspaces to a OpenShift cluster. The chart will deploy a custom image that contains the necessary tools and configurations for developers to work in their workspaces. The image will be built using a Dockerfile that includes the required dependencies and configurations for the developer workspaces. The chart will also include the necessary Kubernetes resources to deploy and manage the developer workspaces on the OpenShift cluster.

Keep the image side of this as a placeholder for future work that I will deal with later but here's some of the details of what the image will contain:

- Python 3.12+ with UV
- Node.js 18+ with npm
- Git
- Code server (VS Code in the browser)
- Jupyter Lab
- Openssh server for remote access
- Common development tools and libraries (e.g., curl, wget, build-essential)
- Custom configurations for the development environment (e.g., bashrc, vimrc)

The HELM chart will be the primary focus of the MVP for this spec.

HELM Chart requirements:

- The chart will be named `dev-workspaces`
- It will include a Deployment resource to deploy the custom image for the developer workspaces
- It needs to build routes to expose the necessary ports for the tools in the image (e.g., code server, Jupyter Lab)
- It will include a PersistentVolumeClaim to provide persistent storage for the developer workspaces
- It will include a Service resource to allow access to the deployed workspaces
- It will include a ConfigMap to store any necessary configuration files for the developer workspaces
- It will include a Secret to store any sensitive information (e.g., SSH keys, API tokens) needed for the developer workspaces
- It will include a HorizontalPodAutoscaler to manage the scaling of the developer workspaces based on resource usage