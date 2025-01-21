# CONTRIBUTING

## VSCode

Recommended plugins:

- `ElixirLS: Elixir support and debugger` (by `ElixirLS`)
- `Credo (Elixir Linter)` (by `pantajoe`)

Recommended `.vscode/settings.json`:

```json
{
    "[elixir]": {
        "editor.formatOnSave": true,
        "editor.formatOnType": true,
    },
    "elixirLS.dialyzerEnabled": true,
    "elixir.credo.strictMode": true
}
```

## AWS CLI

### Dependencies

You must have a python 3.8+ and a `venv` module.

### Get AWS CLI

According to guide in the [official repo](https://github.com/aws/aws-cli?tab=readme-ov-file#installation):

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### `command not found: aws`

It's a python module, which is installed in the local virtual environment you've created earlier. Therefore, each time you open up your terminal to work on the project, don't forget to activate it:

```bash
source .venv/bin/activate
```

### Setup profile

```bash
❯ # Create a profile with CLI
❯ aws configure --profile local
AWS Access Key ID [None]: some-value
AWS Secret Access Key [None]: some-other-value
Default region name [None]: idk
Default output format [None]: 
❯ # Check that the config file was created
❯ cat ~/.aws/config
[profile local]
region = idk
❯ # Append endpoint_url setting so that CLI sends requests to the local server
❯ echo "endpoint_url = http://localhost:8080/api" >>~/.aws/config
❯ # The resulting config should look something like this
❯ cat ~/.aws/config
[profile local]
region = idk
endpoint_url = http://localhost:8080/api
```

## Multi-node basic setup

### Local

Terminal 1:

```bash
elixir \
    --name server@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- brain
```

Terminal 2:

```bash
elixir \
    --name client@127.0.0.1 \
    --cookie cookie-example \
    -S mix run -- storage-agent --brain-name server@127.0.0.1 --client-id sherlock-holmes --directory sos-data
```

### Docker

#### Build an image

```bash
docker buildx build \
    --file Dockerfile \
    --tag sos-playground:1.0 \
    --load .    
```

#### Create a network

```bash
docker network create sos-playground-network
```

#### Run containers

**IMPORTANT**: Node connection only works with 'valid' hostnames. Therefore, if you want to choose some other hostname (`--name`), make sure it contains a dot (`.`).

Brain container:

```bash
docker run \
    --rm \
    -it \
    --network=sos-playground-network \
    --name=sos.server sos-playground:1.0
```

Storage agent container:

```bash
docker run \
    --rm \
    -it \
    --network=sos-playground-network \
    --name=sos.client sos-playground:1.0
```

#### Inside containers

Inside brain container:

```bash
elixir \
    --name server@sos.server \
    --cookie cookie-example \
    -S mix run -- brain
```

Inside storage agent container:

```bash
elixir \
    --name client@sos.client \
    --cookie cookie-example \
    -S mix run -- storage-agent --brain-name server@sos.server --client-id sherlock-holmes --directory sos-data
```
