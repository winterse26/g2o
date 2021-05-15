FROM amazoncorretto:8-alpine AS builder

WORKDIR /root

RUN apk --no-cache update && apk --no-cache add \
    git \
    cmake \
    make \
    g++ \
    eigen-dev \
    suitesparse-dev \
    protobuf-dev \
    swig

RUN git clone https://github.com/google/benchmark.git \
    && git clone https://github.com/google/googletest.git benchmark/googletest \
    && cd benchmark \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release ../ \
    && make install

COPY . /root/g2o

RUN cd g2o \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release \
             -DG2O_BUILD_BENCHMARKS=ON \
             -DG2O_BUILD_EXAMPLES=OFF \
             ../ \
    && make

FROM amazoncorretto:8-alpine AS lib

WORKDIR /root

COPY --from=builder /root/g2o/lib /root/g2o/lib
COPY --from=builder /root/g2o/bin /root/g2o/bin
COPY --from=builder /root/g2o/build/swig/*.java /root/g2o/java/

RUN apk --no-cache update && apk --no-cache add \
    eigen \
    suitesparse \
    libprotobuf

FROM lib AS cli

ENTRYPOINT ["/root/g2o/bin/g2o"]
CMD ["-h"]

FROM lib as hadoop

WORKDIR /root

RUN apk --no-cache update && apk --no-cache add \
    libc6-compat \
    && ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2
