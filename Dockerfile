FROM ubuntu:20.04 as build

# needed to install tzdata in disco
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
	build-essential \
	cmake \
	pkg-config \
	qt5-default \
	libboost-dev \
	libasound2-dev \
	libssl-dev \
	libspeechd-dev \
	libzeroc-ice-dev \
	libpulse-dev \
	libcap-dev \
	libprotobuf-dev \
	protobuf-compiler \
	protobuf-compiler-grpc \
	libprotoc-dev \
	libogg-dev \
	libavahi-compat-libdnssd-dev \
	libsndfile1-dev \
	libgrpc++-dev \
	libxi-dev \
	libbz2-dev \
	&& rm -rf /var/lib/apt/lists/*

COPY . /root/mumble
WORKDIR /root/mumble/build

RUN cmake -Dclient=OFF -DCMAKE_BUILD_TYPE=Release -Dgrpc=ON -Dplugins=OFF ..
RUN make -j $(nproc)

FROM ubuntu:20.04 as release

RUN adduser murmurd
RUN apt-get update && apt-get install --no-install-recommends -y \
	libcap2 \
	libzeroc-ice3.7 \
	'^libprotobuf[0-9]+$' \
	'^libgrpc[0-9]+$' \
	libgrpc++1 \
	libavahi-compat-libdnssd1 \
	libqt5core5a \
	libqt5network5 \
	libqt5sql5 \
	libqt5xml5 \
	libqt5dbus5 \
    libqt5sql5-mysql \
    libmysqlclient-dev \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=build /root/mumble/build/mumble-server /usr/bin/murmurd
COPY --from=build /root/mumble/build/mumble-server.ini /etc/murmurd/murmurd.ini

ARG DB_NAME DB_DRIVER DB_USER DB_PASSWORD DB_HOST DB_PORT SERVER_PASSWORD SUPER_USER_PASSWORD

RUN sed -i 's/database=/database='"${DB_NAME}"'/' /etc/murmurd/murmurd.ini \
    && sed -i 's/;dbDriver=QMYSQL/dbDriver='"${DB_DRIVER}"'/' /etc/murmurd/murmurd.ini \
    && sed -i 's/;dbUsername=/dbUsername='"${DB_USER}"'/' /etc/murmurd/murmurd.ini \
    && sed -i 's/;dbPassword=/dbPassword='"${DB_PASSWORD}"'/' /etc/murmurd/murmurd.ini \
    && sed -i 's/;dbHost=/dbHost='"${DB_HOST}"'/' /etc/murmurd/murmurd.ini \
    && sed -i 's/;dbPort=/dbPort='"${DB_PORT}"'/' /etc/murmurd/murmurd.ini \
	&& sed -i 's/serverpassword=/serverpassword='"${SERVER_PASSWORD}"'/' /etc/murmurd/murmurd.ini


USER murmurd

CMD /usr/bin/murmurd -v -fg -ini /etc/murmurd/murmurd.ini -supw ${SUPER_USER_PASSWORD} && /usr/bin/murmurd -v -fg -ini /etc/murmurd/murmurd.ini