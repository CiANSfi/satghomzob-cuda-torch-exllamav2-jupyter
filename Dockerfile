FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Python, PyTorch
RUN apt-get update && apt-get install -y python3-pip python3-dev git wget vim screen && \
	apt-get install ninja-build && ln -s /usr/bin/python3 /usr/bin/python && \
	pip install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
	rm -rf /var/lib/apt/lists/

# Golang for Hugging Face Model Downloader
RUN wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz

# Install hfdownloader
RUN git clone https://github.com/bodaay/HuggingFaceModelDownloader /HuggingFaceModelDownloader && \
	cd /HuggingFaceModelDownloader/ && PATH=$PATH:/usr/local/go/bin ./BuildLinuxAmd64.sh && \
	chmod +x /HuggingFaceModelDownloader/output/hfdownloader_linux_amd64_1.2.9 && \
        mv /HuggingFaceModelDownloader/output/hfdownloader_linux_amd64_1.2.9 /usr/local/bin/hfdownloader && \
	mkdir /models

# Add non-root user for security
ENV PATH="${PATH}:/usr/local/go/bin"
RUN useradd -ms /bin/bash container_user && \
	chown -R container_user:container_user /models /HuggingFaceModelDownloader
USER container_user
ENV PATH="/home/container_user/.local/bin:${PATH}"
WORKDIR /home/container_user

# Clone exllamav2 suite repos
RUN git clone https://github.com/turboderp/exllamav2 /home/container_user/exllamav2 && \
	git clone https://github.com/theroyallab/tabbyAPI /home/container_user/tabbyAPI && \
	git clone https://github.com/turboderp/exui /home/container_user/exui && \
	chown -R container_user:container_user /home/container_user/*

# Dependencies for exllamav2 and exui
RUN pip install --user pandas \
	ninja \
	fastparquet \
	"safetensors>=0.3.2" \
	"sentencepiece>=0.1.97" \
	pygments \
	websockets \
	regex \
	pynvml \
	"exllamav2>=0.0.10" \ 
	"Flask>=2.3.2" \
	"waitress>=2.1.2"
RUN MAX_JOBS=4 pip install --user flash-attn --no-build-isolation

# Dependencies for tabby
RUN pip install --user fastapi \
        "pydantic >= 2.0.0" \
        PyYAML \
        progress \
	uvicorn \
	"jinja2 >= 3.0.0" \
	colorlog	

# Other Python dependencies
RUN pip install --user transformers jupyterlab-vim polars

# Expose ports for Jupyter Lab and exllama
EXPOSE 8888 5000

ENTRYPOINT ["/bin/bash"]
