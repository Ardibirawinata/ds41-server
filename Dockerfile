FROM ubuntu:22.04 AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates git cmake build-essential \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch runtime/deepseek41 https://github.com/vcruz305/llama.cpp
WORKDIR /src/llama.cpp
RUN grep -q '"deepseek41"' src/llama-arch.cpp \
    || (echo "FATAL: branch ini tidak memuat arch deepseek41" && exit 1)
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=OFF \
        -DGGML_NATIVE=OFF -DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_FMA=ON -DGGML_F16C=ON \
    && cmake --build build -j"$(nproc)" --target llama-server

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/llama.cpp/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=build /src/llama.cpp/build/bin/*.so* /usr/local/lib/
RUN ldconfig && useradd -m -u 1000 appuser
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh
USER appuser
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
