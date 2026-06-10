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
# Miniforge는 conda-forge 기반 conda 배포판이라 GitHub Actions에서 더 안정적이다.
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

# 8. Binder/일반 사용자를 위한 권한 설정
# rocker/tidyverse 이미지에는 rstudio 사용자가 있다.
ENV NB_USER=rstudio
ENV HOME=/home/rstudio

RUN chown -R rstudio:rstudio /opt/conda /home/rstudio

# 9. 기본 실행 경로 설정
WORKDIR /home/rstudio

USER rstudio
