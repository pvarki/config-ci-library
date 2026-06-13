FROM bash:latest AS production
RUN echo $(date -u +%Y%m%dT%H%M) >/build_date.txt
