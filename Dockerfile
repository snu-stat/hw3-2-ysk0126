# 1. 기반 이미지 설정
FROM rocker/tidyverse:4.4.0

# 2. 시스템 의존성 설치
USER root
RUN apt-get update && apt-get install -y \
    wget \
    git \
    ca-certificates \
    imagemagick \
    libmagick++-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Miniforge 설치
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

RUN wget --quiet \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh && \
    conda config --system --set channel_priority strict

# 4. reticulate용 Python 환경 생성
RUN conda create -n r-reticulate -c conda-forge --override-channels \
    python=3.10 \
    numpy \
    pandas \
    matplotlib \
    scipy \
    ipykernel \
    notebook \
    jupyterlab \
    jupyterhub \
    -y && \
    conda clean -afy

# 5. r-reticulate 환경을 기본 PATH에 추가
ENV PATH=/opt/conda/envs/r-reticulate/bin:${CONDA_DIR}/bin:${PATH}
ENV RETICULATE_PYTHON=/opt/conda/envs/r-reticulate/bin/python

# 6. Jupyter kernel 등록
RUN python -m ipykernel install \
    --name r-reticulate \
    --display-name "Python (r-reticulate)" \
    --prefix=/opt/conda

# 7. R 패키지 설치
RUN R -e "install.packages(c('reticulate', 'remotes', 'IRkernel', 'NHANES', 'Lahman', 'mosaic'), repos = 'https://cloud.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)"

# 8. Binder 사용자 설정
ENV NB_USER=rstudio
ENV USER=rstudio
ENV HOME=/home/rstudio

# 9. 기본 실행 경로 설정
WORKDIR /home/rstudio

# 10. 저장소 파일들을 컨테이너 안으로 복사
COPY --chown=rstudio:rstudio . /home/rstudio/

# 11. 권한 설정
RUN chown -R rstudio:rstudio /opt/conda /home/rstudio

# 12. rocker 이미지에서 inherited entrypoint가 있으면 Binder 실행을 방해할 수 있으므로 제거
ENTRYPOINT []

USER rstudio
