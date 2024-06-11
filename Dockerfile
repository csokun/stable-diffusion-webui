FROM nvidia/cuda:12.4.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y curl wget libgl1 libglib2.0-0 python3-pip python-is-python3 git \
	ffmpeg libx264-dev && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# perftools
RUN apt-get update && apt-get install --no-install-recommends -y google-perftools

COPY requirements_docker.txt requirements_versions.txt requirements.txt /tmp/
RUN --mount=type=cache,target=/root/.cache \
	pip install -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt -r /tmp/requirements.txt

RUN --mount=type=cache,target=/root/.cache \
	pip install -U xformers --index-url https://download.pytorch.org/whl/cu121

RUN curl -fsL -o /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
	chmod +x /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2

RUN apt-get install bc -y

# controlnet
RUN --mount=type=cache,target=/root/.cache \
	pip install -U https://github.com/huchenlei/HandRefinerPortable/releases/download/v1.0.1/handrefinerportable-2024.2.12.0-py2.py3-none-any.whl --prefer-binary \
	pip install -U https://github.com/huchenlei/Depth-Anything/releases/download/v1.0.0/depth_anything-2024.1.22.0-py2.py3-none-any.whl --prefer-binary \
	pip install -U https://github.com/sdbds/DSINE/releases/download/1.0.2/dsine-2024.3.23-py3-none-any.whl --prefer-binary

RUN adduser --disabled-password --gecos '' user && \
	mkdir -p /app /data /app/models /app/extensions

RUN chown -R user:user /app

WORKDIR /app
USER user

COPY --chown=user:user . /app 

CMD [ "sh", "-c", "python launch.py ${CMDARGS}" ]