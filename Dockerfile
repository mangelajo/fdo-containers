FROM centos:stream8 AS fdo-base

RUN yum update -y && yum install -y cargo gcc golang git-core openssl-devel
RUN git clone https://github.com/fedora-iot/fido-device-onboard-rs.git && cd fido-device-onboard-rs && git checkout v0.3.0 && cargo build --release --features openssl-kdf/deny_custom,fdo-data-formats/use_noninteroperable_kdf

FROM registry.access.redhat.com/ubi8/ubi-minimal AS fdo-manufacturing-server
COPY --from=fdo-base /fido-device-onboard-rs/target/release/fdo-manufacturing-server /usr/local/bin
RUN mkdir -p /etc/fdo/sessions
RUN mkdir -p /etc/fdo/manufacturing-server.conf.d
ADD config/manufacturing-server.yml /etc/fdo/manufacturing-server.yml
ENV LOG_LEVEL=trace
CMD ["fdo-manufacturing-server"]

FROM registry.access.redhat.com/ubi8/ubi-minimal AS fdo-rendezvous-server
COPY --from=fdo-base /fido-device-onboard-rs/target/release/fdo-rendezvous-server /usr/local/bin
RUN mkdir -p /etc/fdo/sessions
RUN mkdir -p /etc/fdo/rendezvous-server.conf.d
ADD config/rendezvous-server.yml /etc/fdo/rendezvous-server.yml
ENV LOG_LEVEL=trace
CMD ["fdo-rendezvous-server"]

FROM registry.access.redhat.com/ubi8/ubi-minimal AS fdo-owner-onboarding-server
COPY --from=fdo-base /fido-device-onboard-rs/target/release/fdo-owner-onboarding-server /usr/local/bin
RUN mkdir -p /etc/fdo/sessions
RUN mkdir -p /etc/fdo/owner-onboarding-server.conf.d
ADD config/owner-onboarding-server.yml /etc/fdo/owner-onboarding-server.yml
ADD config/owner-addresses.yml /etc/fdo/owner-addresses.yml
ENV LOG_LEVEL=trace
ENV ALLOW_NONINTEROPERABLE_KDF=1
CMD ["fdo-owner-onboarding-server"]
