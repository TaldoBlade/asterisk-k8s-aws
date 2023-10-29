import docker  # Import the docker module
import datetime

# Create a Docker client
client = docker.from_env()  # This is used so the script can talk to the docker daemon. from_env() connects to the default socket
current_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")

config = {
    'detach': True,
    'ports': {'5060/tcp': 5060},
    'name': f'asterisk_container_{current_time}'
}

asterisk_image = 'andrius/asterisk'
container = client.containers.run(asterisk_image, **config)  # Change the image name to 'asterisk'

#print(f"Container ID: {container.id}")